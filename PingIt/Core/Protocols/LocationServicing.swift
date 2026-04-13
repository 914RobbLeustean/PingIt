import CoreLocation

protocol LocationServicing {
    var currentLocation: CLLocation? { get }
    var authorizationStatus: CLAuthorizationStatus { get }
    func requestAuthorization()
    func startUpdatingLocation()
    func stopUpdatingLocation()
    func isWithinClujBoundary(_ coordinate: CLLocationCoordinate2D) -> Bool
}
