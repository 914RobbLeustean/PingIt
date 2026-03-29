import Foundation
import FirebaseAuth

@Observable
final class PingDetailViewModel {
    let ping: Ping
    private var authService: AuthService?
    private var pingService: PingService?
    private var chatService: ChatService?
    private var userService: UserService?
    private var isConfigured = false

    private(set) var creator: User?
    private(set) var isDeleting = false
    private(set) var didDeletePing = false
    private(set) var errorMessage: String?
    private(set) var countdownText: String

    private var countdownTask: Task<Void, Never>?

    var isCreator: Bool {
        authService?.currentUser?.uid == ping.creatorId
    }

    init(ping: Ping) {
        self.ping = ping
        self.countdownText = ping.expiresAt.countdownDescription
    }

    func configure(
        authService: AuthService,
        pingService: PingService,
        chatService: ChatService,
        userService: UserService
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
            }
        }
    }

    func stopCountdownTimer() {
        countdownTask?.cancel()
        countdownTask = nil
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
    }
}
