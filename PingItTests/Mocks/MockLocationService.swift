import CoreLocation
import Observation
@testable import PingIt

@Observable
@MainActor
final class MockLocationService: LocationServicing {
    var currentLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var boundaryResult = true

    var requestAuthorizationCalled = false
    var startUpdatingCalled = false
    var stopUpdatingCalled = false

    func requestAuthorization() {
        requestAuthorizationCalled = true
    }

    func startUpdatingLocation() {
        startUpdatingCalled = true
    }

    func stopUpdatingLocation() {
        stopUpdatingCalled = true
    }

    func isWithinClujBoundary(_ coordinate: CLLocationCoordinate2D) -> Bool {
        boundaryResult
    }
}
