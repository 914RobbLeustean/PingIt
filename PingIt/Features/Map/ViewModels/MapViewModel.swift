import Foundation
import CoreLocation
import FirebaseFirestore
import MapKit

@Observable
final class MapViewModel {
    private var pingService: (any PingServicing)?
    private var locationService: (any LocationServicing)?
    private var blockService: (any BlockServicing)?
    private var listenerRegistration: ListenerHandle?
    private var isConfigured = false

    private var allPings: [Ping] = []
    private(set) var pings: [Ping] = []
    private(set) var clusters: [PingCluster] = []
    private(set) var unclusteredPings: [Ping] = []
    private(set) var isLoading = false
    var errorMessage: String?
    var visibleRegion: MKCoordinateRegion?

    var hotPingIds: Set<String> {
        let sorted = pings.sorted { $0.hotScore > $1.hotScore }
        let topTen = sorted.prefix(10)
        let hotOnes = topTen.filter(\.isHot)
        return Set(hotOnes.compactMap(\.id))
    }

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
            ping.expiresAt > ServerTime.now
            && !(blockService?.isBlocked(ping.creatorId) ?? false)
        }
        updateClusters()
    }

    func updateClusters() {
        guard let region = visibleRegion else {
            unclusteredPings = pings
            clusters = []
            return
        }

        let clusterThreshold = region.span.latitudeDelta * 0.08
        var assigned = Set<String>()
        var newClusters: [PingCluster] = []
        var singles: [Ping] = []
        let hotIds = hotPingIds

        for ping in pings {
            guard let pingId = ping.id, !assigned.contains(pingId) else { continue }

            var group = [ping]
            assigned.insert(pingId)

            for other in pings {
                guard let otherId = other.id, !assigned.contains(otherId) else { continue }
                let latDiff = abs(ping.location.latitude - other.location.latitude)
                let lonDiff = abs(ping.location.longitude - other.location.longitude)
                if latDiff < clusterThreshold && lonDiff < clusterThreshold {
                    group.append(other)
                    assigned.insert(otherId)
                }
            }

            if group.count >= 2 {
                newClusters.append(PingCluster(pings: group, hotPingIds: hotIds))
            } else {
                singles.append(ping)
            }
        }

        clusters = newClusters
        unclusteredPings = singles
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
