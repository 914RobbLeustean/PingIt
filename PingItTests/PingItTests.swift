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
        #expect(description.contains("45m"))
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

    @Test("Single boost is not enough to be hot")
    func singleBoostNotHot() {
        let ping = makePing(boostCount: 1, expiresInHours: 48)
        #expect(ping.isHot == false)
    }

    @Test("Two boosts with sufficient score is hot")
    func twoBoostsCanBeHot() {
        let ping = makePing(boostCount: 2, participantCount: 1, expiresInHours: 24)
        // score = 2*2 + 1 + 24*0.1 = 4 + 1 + 2.4 = 7.4
        #expect(ping.isHot)
    }

    @Test("Two boosts with low score is not hot")
    func twoBoostsLowScoreNotHot() {
        let ping = makePing(boostCount: 2, participantCount: 0, expiresInHours: 0.1)
        // score = 2*2 + 0 + 0.1*0.1 = 4.01 (< 5.0)
        #expect(ping.isHot == false)
    }

    @Test("Time component uses reduced weight (0.1)")
    func timeWeightIsReduced() {
        let ping = makePing(boostCount: 0, expiresInHours: 48)
        // score = 0 + 0 + 48*0.1 = 4.8 (not 24.0 at old 0.5 weight)
        #expect(ping.hotScore < 5.0)
    }
}

// MARK: - Username Validation Tests

struct UsernameValidationTests {
    @Test func validUsernamesAccepted() {
        let vm = LoginViewModel()
        vm.username = "john_doe"
        #expect(vm.isUsernameValid)
        #expect(vm.usernameValidationMessage == nil)
    }

    @Test func tooShortUsernameRejected() {
        let vm = LoginViewModel()
        vm.username = "ab"
        #expect(vm.isUsernameValid == false)
        #expect(vm.usernameValidationMessage != nil)
    }

    @Test func tooLongUsernameRejected() {
        let vm = LoginViewModel()
        vm.username = String(repeating: "a", count: 21)
        #expect(vm.isUsernameValid == false)
        #expect(vm.usernameValidationMessage != nil)
    }

    @Test func specialCharactersRejected() {
        let vm = LoginViewModel()
        vm.username = "john doe!"
        #expect(vm.isUsernameValid == false)
        #expect(vm.usernameValidationMessage != nil)
    }

    @Test func underscoresAllowed() {
        let vm = LoginViewModel()
        vm.username = "john_doe_123"
        #expect(vm.isUsernameValid)
    }

    @Test func emptyUsernameIsInvalid() {
        let vm = LoginViewModel()
        vm.username = ""
        #expect(vm.isUsernameValid == false)
        // No validation message for empty (user hasn't started typing)
        #expect(vm.usernameValidationMessage == nil)
    }

    @Test(arguments: [
        ("abc", true),         // Minimum length
        ("ab", false),         // Below minimum
        ("user_123", true),    // Valid with underscore and numbers
        ("a b c", false),      // Spaces not allowed
        ("user@name", false),  // Special chars not allowed
    ])
    func usernameValidation(username: String, expected: Bool) {
        let vm = LoginViewModel()
        vm.username = username
        #expect(vm.isUsernameValid == expected)
    }

    @Test func canSubmitFalseWhenSignUpWithInvalidUsername() {
        let vm = LoginViewModel()
        vm.isSignUp = true
        vm.email = "test@test.com"
        vm.password = "password123"
        vm.username = "ab" // Too short
        #expect(vm.canSubmit == false)
    }

    @Test func canSubmitTrueWhenSignUpWithValidFields() {
        let vm = LoginViewModel()
        vm.isSignUp = true
        vm.email = "test@test.com"
        vm.password = "password123"
        vm.username = "validuser"
        #expect(vm.canSubmit)
    }

    @Test func canSubmitTrueForSignInWithoutUsername() {
        let vm = LoginViewModel()
        vm.isSignUp = false
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
