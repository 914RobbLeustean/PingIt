import Foundation

@Observable
final class PingDetailViewModel {
    private(set) var ping: Ping
    private var authService: (any AuthServicing)?
    private var pingService: (any PingServicing)?
    private var chatService: (any ChatServicing)?
    private var userService: (any UserServicing)?
    private var analyticsService: (any AnalyticsServicing)?
    private var isConfigured = false

    private(set) var creator: User?
    private(set) var isDeleting = false
    private(set) var didDeletePing = false
    private(set) var errorMessage: String?
    private(set) var countdownText: String
    private(set) var hasUserBoosted = false
    private(set) var isBoosting = false
    private(set) var isCheckingBoostStatus = true
    private(set) var isAttending = false
    private(set) var isTogglingRSVP = false
    private(set) var isCheckingRSVPStatus = true
    var pingUnavailable = false

    var canBoost: Bool {
        !isCreator && !hasUserBoosted && !isBoosting && !isCheckingBoostStatus
    }

    var canToggleRSVP: Bool {
        !isCreator && !isTogglingRSVP && !isCheckingRSVPStatus
    }

    private var countdownTask: Task<Void, Never>?
    private var pingListener: ListenerHandle?

    var isCreator: Bool {
        authService?.currentUser?.uid == ping.creatorId
    }

    var pingCategory: PingCategory? {
        ping.category.flatMap(PingCategory.init(rawValue:))
    }

    var urgency: PingUrgency {
        .from(expiresAt: ping.expiresAt)
    }

    var shouldHideCreatorIdentity: Bool {
        guard let creator, creator.isPrivateProfile else { return false }
        return !isCreator
    }

    init(ping: Ping) {
        self.ping = ping
        self.countdownText = ping.expiresAt.countdownDescription
    }

    func configure(
        authService: any AuthServicing,
        pingService: any PingServicing,
        chatService: any ChatServicing,
        userService: any UserServicing,
        analyticsService: (any AnalyticsServicing)? = nil
    ) {
        guard !isConfigured else { return }
        self.authService = authService
        self.pingService = pingService
        self.chatService = chatService
        self.userService = userService
        self.analyticsService = analyticsService
        isConfigured = true
    }

    func loadCreator() async {
        guard let userService else { return }
        do {
            creator = try await userService.fetchUser(id: ping.creatorId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startCountdownTimer() {
        countdownTask?.cancel()
        countdownTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                guard let self else { return }
                self.countdownText = self.ping.expiresAt.countdownDescription
                if self.ping.expiresAt.timeIntervalSince(ServerTime.now) <= 0 {
                    self.pingUnavailable = true
                    return
                }
            }
        }
    }

    func stopCountdownTimer() {
        countdownTask?.cancel()
        countdownTask = nil
    }

    func startObservingPing() {
        guard let pingService, let pingId = ping.id, pingListener == nil else { return }
        pingListener = pingService.observePing(id: pingId) { [weak self] updatedPing in
            guard let self else { return }
            Task { @MainActor [self] in
                // Don't show unavailable alert if current user initiated the delete
                guard !self.didDeletePing && !self.isDeleting else { return }
                guard let updatedPing, updatedPing.status == .active else {
                    self.pingUnavailable = true
                    return
                }
                // Live-merge so counters (RSVPs, boosts, chat members)
                // update while the screen is open.
                self.ping = updatedPing
            }
        }
    }

    func stopObservingPing() {
        pingListener?.remove()
        pingListener = nil
    }

    func checkBoostStatus() async {
        guard let pingService, let authService,
              let userId = authService.currentUser?.uid,
              let pingId = ping.id else {
            isCheckingBoostStatus = false
            return
        }
        defer { isCheckingBoostStatus = false }
        do {
            hasUserBoosted = try await pingService.hasUserBoostedPing(pingId: pingId, userId: userId)
        } catch {
            // Default to not boosted
        }
    }

    func boostPing() async {
        guard let pingService, let pingId = ping.id, canBoost else { return }
        isBoosting = true
        defer { isBoosting = false }

        do {
            let result = try await pingService.boostPing(pingId: pingId)
            hasUserBoosted = result.didBoost
            ping.boostCount = result.boostCount
            if result.didBoost {
                analyticsService?.logEvent(AnalyticsService.EventName.boostUsed, parameters: nil)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func checkRSVPStatus() async {
        guard let pingService, let authService,
              let userId = authService.currentUser?.uid,
              let pingId = ping.id else {
            isCheckingRSVPStatus = false
            return
        }
        defer { isCheckingRSVPStatus = false }
        do {
            isAttending = try await pingService.hasUserRSVPdPing(pingId: pingId, userId: userId)
        } catch {
            // Default to not attending
        }
    }

    func toggleRSVP() async {
        guard let pingService, let pingId = ping.id, canToggleRSVP else { return }
        isTogglingRSVP = true
        defer { isTogglingRSVP = false }

        do {
            let result = try await pingService.rsvpPing(pingId: pingId)
            isAttending = result.isAttending
            ping.rsvpCount = result.rsvpCount
            analyticsService?.logEvent(AnalyticsService.EventName.rsvpToggled, parameters: [
                AnalyticsService.ParameterName.pingId: pingId,
                AnalyticsService.ParameterName.isAttending: result.isAttending,
            ])
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deletePing() async {
        guard let pingService else { return }
        isDeleting = true
        defer { isDeleting = false }

        do {
            guard let pingId = ping.id else { return }
            try await pingService.deletePing(id: pingId)
            didDeletePing = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    deinit {
        countdownTask?.cancel()
        pingListener?.remove()
    }
}
