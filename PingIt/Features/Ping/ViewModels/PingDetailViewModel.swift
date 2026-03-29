import Foundation
import FirebaseAuth

@Observable
final class PingDetailViewModel {
    let ping: Ping
    private let authService: AuthService
    private let pingService: PingService
    private let chatService: ChatService
    private let userService: UserService

    private(set) var creator: User?
    private(set) var isDeleting = false
    private(set) var didDeletePing = false
    private(set) var errorMessage: String?
    private(set) var countdownText: String

    private var countdownTask: Task<Void, Never>?

    var isCreator: Bool {
        authService.currentUser?.uid == ping.creatorId
    }

    init(
        ping: Ping,
        authService: AuthService,
        pingService: PingService,
        chatService: ChatService,
        userService: UserService
    ) {
        self.ping = ping
        self.authService = authService
        self.pingService = pingService
        self.chatService = chatService
        self.userService = userService
        self.countdownText = ping.expiresAt.countdownDescription
    }

    func loadCreator() async {
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
        isDeleting = true
        defer { isDeleting = false }

        do {
            guard let pingId = ping.id else { return }

            if let chatId = ping.chatId {
                try await chatService.deleteChat(id: chatId)
            }
            try await pingService.deletePing(id: pingId)
            didDeletePing = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    deinit {
        countdownTask?.cancel()
    }
}
