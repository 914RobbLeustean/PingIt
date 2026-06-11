import Testing
import CoreLocation
@testable import PingIt

// MARK: - GeoJSON Boundary Validator Tests

struct GeoJSONBoundaryValidatorTests {
    @Test func clujCenterIsInsideBoundary() {
        let clujCenter = CLLocationCoordinate2D(
            latitude: Constants.Cluj.centerLatitude,
            longitude: Constants.Cluj.centerLongitude
        )
        #expect(GeoJSONBoundaryValidator.contains(clujCenter))
    }

    @Test func bucharestIsOutsideBoundary() {
        let bucharest = CLLocationCoordinate2D(latitude: 44.4268, longitude: 26.1025)
        #expect(GeoJSONBoundaryValidator.contains(bucharest) == false)
    }

    @Test func pointFarNorthIsOutsideBoundary() {
        let farNorth = CLLocationCoordinate2D(latitude: 47.0, longitude: 23.6)
        #expect(GeoJSONBoundaryValidator.contains(farNorth) == false)
    }

    @Test func pointJustInsideBoundary() {
        let insidePoint = CLLocationCoordinate2D(latitude: 46.77, longitude: 23.60)
        #expect(GeoJSONBoundaryValidator.contains(insidePoint))
    }

    @Test func pointJustOutsideBoundary() {
        let outsidePoint = CLLocationCoordinate2D(latitude: 46.50, longitude: 23.60)
        #expect(GeoJSONBoundaryValidator.contains(outsidePoint) == false)
    }

    @Test(arguments: [
        (46.7712, 23.6236, true),   // Cluj center
        (44.4268, 26.1025, false),  // Bucharest
        (46.75, 23.58, true),       // Inside Cluj
        (47.5, 23.6, false),        // North of Cluj
        (46.0, 23.6, false),        // South of Cluj
    ])
    func boundaryCheck(latitude: Double, longitude: Double, expected: Bool) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        #expect(GeoJSONBoundaryValidator.contains(coordinate) == expected)
    }
}

// MARK: - Date Extensions Tests

struct DateExtensionsTests {
    @Test func expiredDateReturnsExpired() {
        let pastDate = Date.now.addingTimeInterval(-3600)
        #expect(pastDate.countdownDescription == "Expired")
    }

    @Test func dateInHoursShowsHoursAndRemaining() {
        let futureDate = Date.now.addingTimeInterval(2 * 3600 + 15 * 60) // ~2h 15m
        let description = futureDate.countdownDescription
        #expect(description.contains("2h"))
        #expect(description.contains("remaining"))
    }

    @Test func dateInMinutesOnlyShowsMinutes() {
        let futureDate = Date.now.addingTimeInterval(45 * 60) // 45m
        let description = futureDate.countdownDescription
        #expect(description.contains("m"))
        #expect(description.contains("remaining"))
        #expect(description.contains("h") == false)
    }

    @Test func dateUnderOneMinuteShowsLessThan() {
        let futureDate = Date.now.addingTimeInterval(30) // 30 seconds
        #expect(futureDate.countdownDescription == "Less than a minute remaining")
    }
}

// MARK: - Constants Tests

struct ConstantsTests {
    @Test func pingMaxTextLengthIs280() {
        #expect(Constants.Ping.maxTextLength == 280)
    }

    @Test func expirationPresetsAreCorrect() {
        let presets = Constants.Ping.expirationPresets
        #expect(presets.count == 3)
        #expect(presets[0] == 6 * 3600)   // 6 hours
        #expect(presets[1] == 24 * 3600)  // 24 hours
        #expect(presets[2] == 48 * 3600)  // 48 hours
    }

    @Test func clujCenterCoordinatesAreValid() {
        #expect(Constants.Cluj.centerLatitude == 46.7712)
        #expect(Constants.Cluj.centerLongitude == 23.6236)
    }

    @Test func rateLimitsAreDefined() {
        #expect(Constants.RateLimit.maxPingsPerHour == 5)
        #expect(Constants.RateLimit.maxPingsPerDay == 10)
        #expect(Constants.RateLimit.maxMessagesPerTenSeconds == 6)
    }
}

// MARK: - Ping Model Tests

struct PingModelTests {
    @Test func pingStatusRawValues() {
        #expect(Ping.PingStatus.active.rawValue == "active")
        #expect(Ping.PingStatus.expired.rawValue == "expired")
        #expect(Ping.PingStatus.removed.rawValue == "removed")
    }
}

// MARK: - Hot Score Tests

import FirebaseFirestore

@Suite("Ping Hot Score")
struct PingHotScoreTests {

    private func makePing(
        boostCount: Int = 0,
        participantCount: Int = 0,
        expiresInHours: Double = 24
    ) -> Ping {
        Ping(
            creatorId: "user1",
            text: "Test",
            location: GeoPoint(latitude: 46.77, longitude: 23.62),
            geohash: "",
            expiresAt: Date.now.addingTimeInterval(expiresInHours * 3600),
            status: .active,
            boostCount: boostCount,
            participantCount: participantCount
        )
    }

    @Test("Zero-engagement ping is never hot regardless of time remaining")
    func zeroEngagementNotHot() {
        let ping = makePing(boostCount: 0, expiresInHours: 48)
        #expect(ping.isHot == false)
    }

    @Test("Two boosts is not enough — need at least 3")
    func twoBoostsNotHot() {
        let ping = makePing(boostCount: 2, participantCount: 0, expiresInHours: 48)
        // score = 4 + 0 + 2.0 = 6.0 but boostCount < 3
        #expect(ping.isHot == false)
    }

    @Test("Three boosts with long expiration is hot")
    func threeBoostsLongExpirationHot() {
        let ping = makePing(boostCount: 3, participantCount: 0, expiresInHours: 48)
        // score = 6 + 0 + 2.0(capped) = 8.0
        #expect(ping.isHot)
    }

    @Test("Three boosts with short expiration and no participants is not hot")
    func threeBoostsShortExpirationNotHot() {
        let ping = makePing(boostCount: 3, participantCount: 0, expiresInHours: 6)
        // score = 6 + 0 + 0.6 = 6.6 (< 8.0)
        #expect(ping.isHot == false)
    }

    @Test("Three boosts with participants and short expiration is hot")
    func threeBoostsWithParticipantsHot() {
        let ping = makePing(boostCount: 3, participantCount: 2, expiresInHours: 6)
        // score = 6 + 2 + 0.6 = 8.6
        #expect(ping.isHot)
    }

    @Test("Time contribution capped at 2.0")
    func timeContributionCapped() {
        let shortPing = makePing(boostCount: 0, expiresInHours: 6)
        let longPing = makePing(boostCount: 0, expiresInHours: 48)
        // 6h: 0 + 0 + 0.6 = 0.6
        // 48h: 0 + 0 + 2.0(capped) = 2.0
        #expect(shortPing.hotScore < 1.0)
        #expect(longPing.hotScore == 2.0)
    }

    @Test("Four boosts on a dying ping is hot")
    func fourBoostsDyingPingHot() {
        let ping = makePing(boostCount: 4, participantCount: 0, expiresInHours: 1)
        // score = 8 + 0 + 0.1 = 8.1
        #expect(ping.isHot)
    }
}

// MARK: - Username Validation Tests

@MainActor
struct UsernameValidationTests {
    @Test func validUsernamesAccepted() {
        let vm = RegisterViewModel()
        vm.username = "john_doe"
        #expect(vm.isUsernameFormatValid)
        #expect(vm.usernameFormatMessage == nil)
    }

    @Test func tooShortUsernameRejected() {
        let vm = RegisterViewModel()
        vm.username = "ab"
        #expect(vm.isUsernameFormatValid == false)
        #expect(vm.usernameFormatMessage != nil)
    }

    @Test func tooLongUsernameRejected() {
        let vm = RegisterViewModel()
        vm.username = String(repeating: "a", count: 21)
        #expect(vm.isUsernameFormatValid == false)
        #expect(vm.usernameFormatMessage != nil)
    }

    @Test func specialCharactersRejected() {
        let vm = RegisterViewModel()
        vm.username = "john doe!"
        #expect(vm.isUsernameFormatValid == false)
        #expect(vm.usernameFormatMessage != nil)
    }

    @Test func underscoresAllowed() {
        let vm = RegisterViewModel()
        vm.username = "john_doe_123"
        #expect(vm.isUsernameFormatValid)
    }

    @Test func emptyUsernameIsInvalid() {
        let vm = RegisterViewModel()
        vm.username = ""
        #expect(vm.isUsernameFormatValid == false)
        // No validation message for empty (user hasn't started typing)
        #expect(vm.usernameFormatMessage == nil)
    }

    @Test(arguments: [
        ("abc", true),         // Minimum length
        ("ab", false),         // Below minimum
        ("user_123", true),    // Valid with underscore and numbers
        ("a b c", false),      // Spaces not allowed
        ("user@name", false),  // Special chars not allowed
    ])
    func usernameValidation(username: String, expected: Bool) {
        let vm = RegisterViewModel()
        vm.username = username
        #expect(vm.isUsernameFormatValid == expected)
    }

    @Test func canSubmitFalseWhenRegisteringWithInvalidUsername() {
        let vm = RegisterViewModel()
        vm.email = "test@test.com"
        vm.password = "Password1"
        vm.confirmPassword = "Password1"
        vm.passwordDidChange()
        vm.hasAcceptedTerms = true
        vm.username = "ab" // Too short
        vm.setUsernameAvailabilityForTesting(.available)
        #expect(vm.canSubmit == false)
    }

    @Test func canSubmitTrueWhenRegisteringWithValidFields() {
        let vm = RegisterViewModel()
        vm.email = "test@test.com"
        vm.password = "Password1"
        vm.confirmPassword = "Password1"
        vm.passwordDidChange()
        vm.hasAcceptedTerms = true
        vm.username = "validuser"
        vm.setUsernameAvailabilityForTesting(.available)
        #expect(vm.canSubmit)
    }

    @Test func canSubmitTrueForLoginWithoutUsername() {
        let vm = LoginViewModel()
        vm.email = "test@test.com"
        vm.password = "password123"
        #expect(vm.canSubmit)
    }
}

// MARK: - Username Constants Tests

struct UsernameConstantsTests {
    @Test func usernameMinLengthIs3() {
        #expect(Constants.Username.minLength == 3)
    }

    @Test func usernameMaxLengthIs20() {
        #expect(Constants.Username.maxLength == 20)
    }
}
