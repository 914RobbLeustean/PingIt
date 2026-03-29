import Foundation
import CoreLocation
import FirebaseFirestore

@Observable
final class MapViewModel {
    private let pingService: PingService
    private let locationService: LocationService
    private var listenerRegistration: ListenerRegistration?

    private(set) var pings: [Ping] = []
    private(set) var isLoading = false
    var errorMessage: String?

    var userLocation: CLLocation? { locationService.currentLocation }
    var authorizationStatus: CLAuthorizationStatus { locationService.authorizationStatus }

    init(pingService: PingService, locationService: LocationService) {
        self.pingService = pingService
        self.locationService = locationService
    }

    func startObserving() {
        guard listenerRegistration == nil else { return }
        isLoading = true

        listenerRegistration = pingService.observeActivePings { [weak self] pings in
            guard let self else { return }
            Task { @MainActor [self] in
                self.pings = pings
                self.isLoading = false
            }
        }
    }

    func stopObserving() {
        listenerRegistration?.remove()
        listenerRegistration = nil
    }

    func requestLocationPermission() {
        locationService.requestAuthorization()
    }

    func startLocationUpdates() {
        locationService.startUpdatingLocation()
    }

    func stopLocationUpdates() {
        locationService.stopUpdatingLocation()
    }

    deinit {
        listenerRegistration?.remove()
    }
}
