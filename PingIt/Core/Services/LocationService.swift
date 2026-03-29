import Foundation
import CoreLocation

@Observable
final class LocationService: NSObject {
    private let locationManager = CLLocationManager()
    private(set) var currentLocation: CLLocation?
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }

    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    /// Checks if a coordinate falls within the Cluj-Napoca boundary.
    /// Uses a simple radius check for now; will be upgraded to GeoJSON polygon containment.
    func isWithinClujBoundary(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let centerLocation = CLLocation(
            latitude: Constants.Cluj.center.latitude,
            longitude: Constants.Cluj.center.longitude
        )
        let distanceKm = location.distance(from: centerLocation) / 1000.0
        return distanceKm <= Constants.Cluj.radiusKilometers
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}
