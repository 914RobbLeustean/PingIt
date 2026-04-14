import Foundation
import CoreLocation

@Observable
final class MapViewModel {
    private var pingService: (any PingServicing)?
    private var locationService: (any LocationServicing)?
    private var blockService: (any BlockServicing)?
    private var listenerRegistration: ListenerHandle?
    private var isConfigured = false

    private var allPings: [Ping] = []
    private(set) var pings: [Ping] = []
    private(set) var isLoading = false
    var errorMessage: String?

    var userLocation: CLLocation? { locationService?.currentLocation }
    var authorizationStatus: CLAuthorizationStatus { locationService?.authorizationStatus ?? .notDetermined }

    func configure(
        pingService: any PingServicing,
        locationService: any LocationServicing,
        blockService: (any BlockServicing)? = nil
    ) {
        guard !isConfigured else { return }
        self.pingService = pingService
        self.locationService = locationService
        self.blockService = blockService
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
                    self.allPings = pings
                    self.applyBlockFilter()
                    self.errorMessage = nil
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
                self.isLoading = false
            }
        }
    }

    func applyBlockFilter() {
        pings = allPings.filter { ping in
            ping.expiresAt > Date.now
            && !(blockService?.isBlocked(ping.creatorId) ?? false)
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
