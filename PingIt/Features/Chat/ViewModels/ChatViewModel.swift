import Foundation

@Observable
final class ChatViewModel {
    private var authService: (any AuthServicing)?
    private var chatService: (any ChatServicing)?
    private var pingService: (any PingServicing)?
    private var userService: (any UserServicing)?
    private var contentModerationService: (any ContentModeratingServicing)?
    private var blockService: (any BlockServicing)?
    private var rateLimitService: (any RateLimitServicing)?
    private var analyticsService: (any AnalyticsServicing)?
    private var listenerRegistration: ListenerHandle?
    private var pingListener: ListenerHandle?
    private var isConfigured = false

    let chatId: String
    let pingId: String

    private var allMessages: [ChatMessage] = []
    private(set) var messages: [ChatMessage] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var hasMoreMessages = true
    private(set) var isSending = false
    private(set) var errorMessage: String?
    private(set) var hasJoined = false
    private var joinedChatId: String?
    var messageText = ""
    var pingUnavailable = false
    private(set) var userCache: [String: User] = [:]
    private let pageSize = 50

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
        userService: (any UserServicing)? = nil,
        contentModerationService: (any ContentModeratingServicing)? = nil,
        blockService: (any BlockServicing)? = nil,
        rateLimitService: (any RateLimitServicing)? = nil,
        analyticsService: (any AnalyticsServicing)? = nil
    ) {
        guard !isConfigured else { return }
        self.authService = authService
        self.chatService = chatService
        self.pingService = pingService
        self.userService = userService
        self.contentModerationService = contentModerationService
        self.blockService = blockService
        self.rateLimitService = rateLimitService
        self.analyticsService = analyticsService
        isConfigured = true
    }

    func loadInitialMessages() async {
        guard let chatService else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let fetched = try await chatService.fetchMessages(chatId: chatId, before: nil, limit: pageSize)
            allMessages = fetched
            hasMoreMessages = fetched.count >= pageSize
            applyBlockFilter()
            startListeningForNewMessages()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMoreMessages() async {
        guard let chatService, hasMoreMessages, !isLoadingMore else { return }
        guard let oldestDate = allMessages.first?.createdAt else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let older = try await chatService.fetchMessages(chatId: chatId, before: oldestDate, limit: pageSize)
            hasMoreMessages = older.count >= pageSize
            allMessages = older + allMessages
            applyBlockFilter()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func startListeningForNewMessages() {
        guard let chatService, listenerRegistration == nil else { return }
        let after = allMessages.last?.createdAt ?? Date.now

        listenerRegistration = chatService.observeNewMessages(chatId: chatId, after: after) { [weak self] result in
            guard let self else { return }
            Task { @MainActor [self] in
                switch result {
                case .success(let newMessages):
                    let existingIds = Set(self.allMessages.compactMap(\.id))
                    let unique = newMessages.filter { msg in
                        guard let id = msg.id else { return true }
                        return !existingIds.contains(id)
                    }
                    if !unique.isEmpty {
                        self.allMessages.append(contentsOf: unique)
                        self.applyBlockFilter()
                    }
                    self.errorMessage = nil
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func stopObserving() {
        listenerRegistration?.remove()
        listenerRegistration = nil
    }

    func joinChat() async {
        guard let chatService, currentUserId != nil, !hasJoined else { return }
        do {
            _ = try await chatService.joinChatIfNeeded(chatId: chatId)
            joinedChatId = chatId
            hasJoined = true
            analyticsService?.logEvent(AnalyticsService.EventName.chatJoined, parameters: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func leaveChat() async {
        guard let chatService, let joinedChatId else { return }
        do {
            try await chatService.leaveChat(chatId: joinedChatId)
            self.joinedChatId = nil
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
        Task { await fetchMissingUsers() }
    }

    private func fetchMissingUsers() async {
        guard let userService else { return }
        let senderIds = Set(messages.map(\.senderId))
        let missing = senderIds.subtracting(userCache.keys)
        for senderId in missing {
            if let user = try? await userService.fetchUser(id: senderId) {
                userCache[senderId] = user
            }
        }
    }

    func isFirstInGroup(_ message: ChatMessage) -> Bool {
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else { return true }
        if index == 0 { return true }
        return messages[index - 1].senderId != message.senderId
    }

    func isSenderPrivate(for message: ChatMessage) -> Bool {
        guard message.senderId != currentUserId else { return false }
        return userCache[message.senderId]?.isPrivateProfile == true
    }

    deinit {
        listenerRegistration?.remove()
        pingListener?.remove()
    }
}
