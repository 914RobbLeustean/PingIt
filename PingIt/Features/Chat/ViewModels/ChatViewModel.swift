import Foundation

@Observable
final class ChatViewModel {
    private var authService: (any AuthServicing)?
    private var chatService: (any ChatServicing)?
    private var pingService: (any PingServicing)?
    private var contentModerationService: (any ContentModeratingServicing)?
    private var blockService: (any BlockServicing)?
    private var rateLimitService: (any RateLimitServicing)?
    private var listenerRegistration: ListenerHandle?
    private var pingListener: ListenerHandle?
    private var isConfigured = false

    let chatId: String
    let pingId: String

    private var allMessages: [ChatMessage] = []
    private(set) var messages: [ChatMessage] = []
    private(set) var isLoading = false
    private(set) var isSending = false
    private(set) var errorMessage: String?
    private(set) var hasJoined = false
    private var participantDocId: String?
    var messageText = ""
    var pingUnavailable = false

    var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    var currentUserId: String? {
        authService?.currentUser?.uid
    }

    init(chatId: String, pingId: String) {
        self.chatId = chatId
        self.pingId = pingId
    }

    func configure(
        authService: any AuthServicing,
        chatService: any ChatServicing,
        pingService: (any PingServicing)? = nil,
        contentModerationService: (any ContentModeratingServicing)? = nil,
        blockService: (any BlockServicing)? = nil,
        rateLimitService: (any RateLimitServicing)? = nil
    ) {
        guard !isConfigured else { return }
        self.authService = authService
        self.chatService = chatService
        self.pingService = pingService
        self.contentModerationService = contentModerationService
        self.blockService = blockService
        self.rateLimitService = rateLimitService
        isConfigured = true
    }

    func startObserving() {
        guard let chatService, listenerRegistration == nil else { return }
        isLoading = true

        listenerRegistration = chatService.observeMessages(chatId: chatId) { [weak self] result in
            guard let self else { return }
            Task { @MainActor [self] in
                switch result {
                case .success(let messages):
                    self.allMessages = messages
                    self.applyBlockFilter()
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

    func joinChat() async {
        guard let chatService, let currentUserId, !hasJoined else { return }
        do {
            participantDocId = try await chatService.joinChatIfNeeded(chatId: chatId, userId: currentUserId)
            hasJoined = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func leaveChat() async {
        guard let chatService, let participantDocId else { return }
        do {
            try await chatService.leaveChat(participantId: participantDocId)
            self.participantDocId = nil
            hasJoined = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendMessage() async {
        guard let chatService, let currentUserId, canSend else { return }

        guard !pingUnavailable else {
            return
        }

        guard authService?.isEmailVerified == true else {
            errorMessage = PingItError.emailNotVerified.localizedDescription
            return
        }

        if let moderationService = contentModerationService {
            let result = moderationService.check(messageText.trimmingCharacters(in: .whitespacesAndNewlines))
            if case .blocked(let reason) = result {
                errorMessage = reason
                return
            }
        }

        if let rateLimitService {
            let result = rateLimitService.canSendMessage()
            if case .limited = result {
                errorMessage = "You're sending messages too quickly. Please wait a moment."
                return
            }
        }

        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        isSending = true
        defer { isSending = false }

        let message = ChatMessage(
            chatId: chatId,
            senderId: currentUserId,
            text: trimmed
        )

        do {
            try await chatService.sendMessage(message)
            messageText = ""
            rateLimitService?.recordMessageSent()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startObservingPing() {
        guard let pingService, pingListener == nil else { return }
        pingListener = pingService.observePing(id: pingId) { [weak self] updatedPing in
            guard let self else { return }
            Task { @MainActor [self] in
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

    func applyBlockFilter() {
        messages = allMessages.filter { message in
            !(blockService?.isBlocked(message.senderId) ?? false)
        }
    }

    deinit {
        listenerRegistration?.remove()
        pingListener?.remove()
    }
}
