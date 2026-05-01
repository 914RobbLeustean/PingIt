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

    private(set) var displayCoordinates: [String: CLLocationCoordinate2D] = [:]

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
        computeDisplayCoordinates()
        updateClusters()
    }

    private func computeDisplayCoordinates() {
        // ~5 meter proximity threshold for grouping overlapping pins
        let proximityThreshold = 0.00005
        let offsetDistance = 0.00008

        var groups: [[Ping]] = []
        var assigned = Set<String>()

        for ping in pings {
            guard let id = ping.id, !assigned.contains(id) else { continue }
            var group = [ping]
            assigned.insert(id)

            for other in pings {
                guard let otherId = other.id, !assigned.contains(otherId) else { continue }
                if abs(ping.location.latitude - other.location.latitude) < proximityThreshold
                    && abs(ping.location.longitude - other.location.longitude) < proximityThreshold {
                    group.append(other)
                    assigned.insert(otherId)
                }
            }
            groups.append(group)
        }

        var result: [String: CLLocationCoordinate2D] = [:]

        for group in groups {
            if group.count == 1, let ping = group.first, let id = ping.id {
                result[id] = CLLocationCoordinate2D(
                    latitude: ping.location.latitude,
                    longitude: ping.location.longitude
                )
            } else {
                let center = CLLocationCoordinate2D(
                    latitude: group.map(\.location.latitude).reduce(0, +) / Double(group.count),
                    longitude: group.map(\.location.longitude).reduce(0, +) / Double(group.count)
                )
                let angleStep = (2.0 * .pi) / Double(group.count)
                for (index, ping) in group.enumerated() {
                    guard let id = ping.id else { continue }
                    let angle = angleStep * Double(index)
                    result[id] = CLLocationCoordinate2D(
                        latitude: center.latitude + offsetDistance * cos(angle),
                        longitude: center.longitude + offsetDistance * sin(angle)
                    )
                }
            }
        }

        displayCoordinates = result
    }

    func updateClusters() {
        guard let region = visibleRegion else {
            unclusteredPings = pings
            clusters = []
            return
        }

        if region.span.latitudeDelta < 0.005 {
            unclusteredPings = pings
            clusters = []
            return
        }

        let clusterThreshold = region.span.latitudeDelta * 0.03
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
