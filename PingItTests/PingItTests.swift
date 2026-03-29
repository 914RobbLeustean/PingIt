import Testing
import CoreLocation
@testable import PingIt

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
        // A known point inside Cluj-Napoca (near the city center area)
        let insidePoint = CLLocationCoordinate2D(latitude: 46.77, longitude: 23.60)
        #expect(GeoJSONBoundaryValidator.contains(insidePoint))
    }

    @Test func pointJustOutsideBoundary() {
        // A point clearly outside the bounding box
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
