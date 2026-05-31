import Foundation
import CoreLocation
import FirebaseFirestore

enum FeedSortOption: String, CaseIterable, Sendable {
    case newest
    case hottest
    case nearest
    case expiringSoon

    var displayName: String {
        switch self {
        case .newest: "Newest"
        case .hottest: "Hottest"
        case .nearest: "Nearest"
        case .expiringSoon: "Expiring Soon"
        }
    }
}

@MainActor @Observable
final class FeedViewModel {
    private var pingService: (any PingServicing)?
    private var locationService: (any LocationServicing)?
    private var blockService: (any BlockServicing)?
    private var userService: (any UserServicing)?
    private var analyticsService: (any AnalyticsServicing)?
    private var listenerRegistration: ListenerHandle?
    private var isConfigured = false

    private var allPings: [Ping] = []
    private(set) var pings: [Ping] = []
    private(set) var isLoading = false
    private(set) var creatorCache: [String: User] = [:]
    var sortOption: FeedSortOption = .newest

    var sortedPings: [Ping] {
        switch sortOption {
        case .newest:
            return pings.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
        case .hottest:
            return pings.sorted { $0.hotScore > $1.hotScore }
        case .nearest:
            guard let userLocation = locationService?.currentLocation else {
                return pings
            }
            return pings.sorted {
                distance(from: userLocation, to: $0) < distance(from: userLocation, to: $1)
            }
        case .expiringSoon:
            return pings.sorted { $0.expiresAt < $1.expiresAt }
        }
    }

    func configure(
        pingService: any PingServicing,
        locationService: any LocationServicing,
        blockService: (any BlockServicing)? = nil,
        userService: (any UserServicing)? = nil,
        analyticsService: (any AnalyticsServicing)? = nil
    ) {
        guard !isConfigured else { return }
        self.pingService = pingService
        self.locationService = locationService
        self.blockService = blockService
        self.userService = userService
        self.analyticsService = analyticsService
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
                    self.applyFilters()
                case .failure:
                    break
                }
                self.isLoading = false
            }
        }
    }

    func stopObserving() {
        listenerRegistration?.remove()
        listenerRegistration = nil
    }

    func distanceText(for ping: Ping) -> String? {
        guard let userLocation = locationService?.currentLocation else { return nil }
        let pingLocation = CLLocation(latitude: ping.location.latitude, longitude: ping.location.longitude)
        let meters = userLocation.distance(from: pingLocation)
        if meters < 1000 {
            return "\(Int(meters))m away"
        }
        return "\((meters / 1000).formatted(.number.precision(.fractionLength(1))))km away"
    }

    func applyFilters() {
        pings = allPings.filter { ping in
            ping.expiresAt > ServerTime.now
            && !(blockService?.isBlocked(ping.creatorId) ?? false)
        }
        Task { await fetchMissingCreators() }
    }

    private func fetchMissingCreators() async {
        guard let userService else { return }
        let creatorIds = Set(pings.map(\.creatorId))
        let missing = creatorIds.subtracting(creatorCache.keys)
        for creatorId in missing {
            if let user = try? await userService.fetchUser(id: creatorId) {
                creatorCache[creatorId] = user
            }
        }
    }

    private func distance(from location: CLLocation, to ping: Ping) -> CLLocationDistance {
        let pingLocation = CLLocation(latitude: ping.location.latitude, longitude: ping.location.longitude)
        return location.distance(from: pingLocation)
    }

    isolated deinit {
        listenerRegistration?.remove()
    }
}
