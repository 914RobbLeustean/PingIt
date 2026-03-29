import Foundation
import CoreLocation
import FirebaseFirestore

@Observable
final class MapViewModel {
    private var pingService: PingService?
    private var locationService: LocationService?
    private var listenerRegistration: ListenerRegistration?
    private var isConfigured = false

    private(set) var pings: [Ping] = []
    private(set) var isLoading = false
    var errorMessage: String?

    var userLocation: CLLocation? { locationService?.currentLocation }
    var authorizationStatus: CLAuthorizationStatus { locationService?.authorizationStatus ?? .notDetermined }

    func configure(pingService: PingService, locationService: LocationService) {
        guard !isConfigured else { return }
        self.pingService = pingService
        self.locationService = locationService
        isConfigured = true
    }

    func startObserving() {
        guard let pingService, listenerRegistration == nil else { return }
        isLoading = true

        listenerRegistration = pingService.observeActivePings { [weak self] result in
            guard let self else { return }
            Task { @MainActor [self] in
                switch result {
                case .success(let pings):
                    self.pings = pings
                    self.errorMessage = nil
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
                self.isLoading = false
            }
        }
    }

    func stopObserving() {
        listenerRegistration?.remove()
        listenerRegistration = nil
    }

    func requestLocationPermission() {
        locationService?.requestAuthorization()
    }

    func startLocationUpdates() {
        locationService?.startUpdatingLocation()
    }

    func stopLocationUpdates() {
        locationService?.stopUpdatingLocation()
    }

    deinit {
        listenerRegistration?.remove()
    }
}
