import Foundation
import CoreLocation
import FirebaseFirestore
import MapKit

@Observable
final class MapViewModel {
    private var pingService: (any PingServicing)?
    private var locationService: (any LocationServicing)?
    private var blockService: (any BlockServicing)?
    private var recapService: (any PingRecapServicing)?
    private var listenerRegistration: ListenerHandle?
    private var recapListenerRegistration: ListenerHandle?
    private var isConfigured = false

    private var allPings: [Ping] = []
    private(set) var pings: [Ping] = []
    private(set) var clusters: [PingCluster] = []
    private(set) var unclusteredPings: [Ping] = []
    private var allRecaps: [PingRecap] = []
    private(set) var recaps: [PingRecap] = []
    private(set) var isLoading = false
    var currentUserId: String? {
        didSet { applyRecapFilter() }
    }

    private(set) var isHeatmapEnabled = false
    private(set) var heatCells: [HeatCell] = []
    private(set) var isLoadingHeatmap = false
    private var heatmapFetchedAt: Date?
    private static let heatmapCacheSeconds: TimeInterval = 30 * 60

    // Recaps are shown by default but only when zoomed in close, so their
    // ghost markers don't overlap active ping pins at wider zoom. In-memory
    // only (resets ON each launch), matching the heatmap toggle.
    private(set) var isRecapsEnabled = true
    /// Max latitudeDelta (zoom span) at which recap markers render. Tighter
    /// than the clustering thresholds so recaps appear only at neighborhood
    /// zoom, not city/region zoom.
    private static let recapZoomThreshold: CLLocationDegrees = 0.02

    var errorMessage: String?
    var visibleRegion: MKCoordinateRegion? {
        didSet { applyRecapFilter() }
    }

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
        blockService: (any BlockServicing)? = nil,
        recapService: (any PingRecapServicing)? = nil
    ) {
        guard !isConfigured else { return }
        self.pingService = pingService
        self.locationService = locationService
        self.blockService = blockService
        self.recapService = recapService
        isConfigured = true
    }

    func startObserving() {
        startObservingPings()
        startObservingRecaps()
    }

    private func startObservingPings() {
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

    private func startObservingRecaps() {
        guard let recapService, recapListenerRegistration == nil else { return }

        recapListenerRegistration = recapService.observeActiveRecaps { [weak self] result in
            guard let self else { return }
            Task { @MainActor [self] in
                if case .success(let recaps) = result {
                    self.allRecaps = recaps
                    self.applyRecapFilter()
                }
            }
        }
    }

    private func applyRecapFilter() {
        // Hidden when the user toggles recaps off, or when zoomed out past
        // the threshold — at wider zoom recap ghosts overlap active pins.
        guard isRecapsEnabled,
              let region = visibleRegion,
              region.span.latitudeDelta < Self.recapZoomThreshold else {
            recaps = []
            return
        }

        // Empty recaps are visible only to their attendees — a ghost with
        // no photos is just clutter for everyone else.
        recaps = allRecaps.filter {
            $0.ghostExpiresAt > ServerTime.now
            && $0.isVisibleOnMap(to: currentUserId)
        }
    }

    func toggleRecaps() {
        isRecapsEnabled.toggle()
        applyRecapFilter()
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
        recapListenerRegistration?.remove()
        recapListenerRegistration = nil
    }

    // MARK: - Heatmap

    func toggleHeatmap() async {
        isHeatmapEnabled.toggle()
        guard isHeatmapEnabled else { return }
        await loadHeatmapIfStale()
    }

    private func loadHeatmapIfStale() async {
        guard let pingService else { return }
        if let fetchedAt = heatmapFetchedAt,
           ServerTime.now.timeIntervalSince(fetchedAt) < Self.heatmapCacheSeconds,
           !heatCells.isEmpty {
            return
        }

        isLoadingHeatmap = true
        defer { isLoadingHeatmap = false }

        let windowStart = ServerTime.now.addingTimeInterval(-HeatmapBuilder.windowDays * 24 * 3600)
        do {
            let recentPings = try await pingService.fetchPings(createdAfter: windowStart)
            heatCells = HeatmapBuilder.buildCells(from: recentPings, now: ServerTime.now)
            heatmapFetchedAt = ServerTime.now
        } catch {
            errorMessage = error.localizedDescription
            isHeatmapEnabled = false
        }
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
        recapListenerRegistration?.remove()
    }
}
