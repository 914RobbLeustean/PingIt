import Foundation

@Observable
final class PingDetailViewModel {
    let ping: Ping
    private var authService: (any AuthServicing)?
    private var pingService: (any PingServicing)?
    private var chatService: (any ChatServicing)?
    private var userService: (any UserServicing)?
    private var isConfigured = false

    private(set) var creator: User?
    private(set) var isDeleting = false
    private(set) var didDeletePing = false
    private(set) var errorMessage: String?
    private(set) var countdownText: String
    var pingUnavailable = false

    private var countdownTask: Task<Void, Never>?
    private var pingListener: ListenerHandle?

    var isCreator: Bool {
        authService?.currentUser?.uid == ping.creatorId
    }

    init(ping: Ping) {
        self.ping = ping
        self.countdownText = ping.expiresAt.countdownDescription
    }

    func configure(
        authService: any AuthServicing,
        pingService: any PingServicing,
        chatService: any ChatServicing,
        userService: any UserServicing
    ) {
        guard !isConfigured else { return }
        self.authService = authService
        self.pingService = pingService
        self.chatService = chatService
        self.userService = userService
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
                guard !self.didDeletePing else { return }
                if updatedPing == nil || updatedPing?.status != .active {
                    self.pingUnavailable = true
                }
            }
        }
    }

    func stopObservingPing() {
        pingListener?.remove()
        pingListener = nil
    }

    func deletePing() async {
        guard let pingService else { return }
        isDeleting = true
        defer { isDeleting = false }

        do {
            guard let pingId = ping.id else { return }
            try await pingService.deletePingAndChat(pingId: pingId, chatId: ping.chatId)
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
