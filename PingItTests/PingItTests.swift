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

    @Test func dateInHoursShowsHoursAndMinutes() {
        let futureDate = Date.now.addingTimeInterval(2 * 3600 + 15 * 60) // 2h 15m
        let description = futureDate.countdownDescription
        #expect(description.contains("2h"))
        #expect(description.contains("15m"))
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
