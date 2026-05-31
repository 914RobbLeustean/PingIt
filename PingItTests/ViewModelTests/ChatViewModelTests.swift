import Foundation
import Testing
@testable import PingIt

@Suite("ChatViewModel")
@MainActor
struct ChatViewModelTests {

    // MARK: - Helpers

    private func makeVM(
        authService: MockAuthService? = nil,
        chatService: MockChatService? = nil,
        contentModerationService: MockContentModerationService? = nil,
        rateLimitService: MockRateLimitService? = nil,
        chatId: String = "chat-1",
        pingId: String = "ping-1"
    ) -> ChatViewModel {
        let authService = authService ?? MockAuthService()
        let chatService = chatService ?? MockChatService()
        let contentModerationService = contentModerationService ?? MockContentModerationService()
        let rateLimitService = rateLimitService ?? MockRateLimitService()
        let vm = ChatViewModel(chatId: chatId, pingId: pingId)
        vm.configure(authService: authService, chatService: chatService, contentModerationService: contentModerationService, rateLimitService: rateLimitService)
        return vm
    }

    private func authenticatedAuth(uid: String = "user1") -> MockAuthService {
        let auth = MockAuthService()
        auth.currentUser = MockAuthUser(uid: uid, isEmailVerified: true)
        auth.isEmailVerified = true
        return auth
    }

    // MARK: - canSend

    @Test func canSendFalseWhenMessageEmpty() {
        let vm = makeVM(authService: authenticatedAuth())
        vm.messageText = ""
        #expect(vm.canSend == false)
    }

    @Test func canSendFalseWhenWhitespaceOnly() {
        let vm = makeVM(authService: authenticatedAuth())
        vm.messageText = "   "
        #expect(vm.canSend == false)
    }

    @Test func canSendTrueWithText() {
        let vm = makeVM(authService: authenticatedAuth())
        vm.messageText = "Hello!"
        #expect(vm.canSend)
    }

    // MARK: - currentUserId

    @Test func currentUserIdReturnsUid() {
        let vm = makeVM(authService: authenticatedAuth(uid: "abc123"))
        #expect(vm.currentUserId == "abc123")
    }

    @Test func currentUserIdNilWhenNotAuthenticated() {
        let auth = MockAuthService()
        auth.currentUser = nil
        let vm = makeVM(authService: auth)
        #expect(vm.currentUserId == nil)
    }

    // MARK: - loadInitialMessages / stopObserving

    @Test func loadInitialMessagesAttachesListener() async {
        let chat = MockChatService()
        let vm = makeVM(chatService: chat)
        await vm.loadInitialMessages()
        #expect(chat.newMessagesCallback != nil)
    }

    @Test func stopObservingCallsRemoveOnListener() async {
        let chat = MockChatService()
        let vm = makeVM(chatService: chat)
        await vm.loadInitialMessages()
        vm.stopObserving()
        #expect(chat.removeCalled)
    }

    // MARK: - joinChat

    @Test func joinChatSucceeds() async {
        let auth = authenticatedAuth()
        let chat = MockChatService()
        let vm = makeVM(authService: auth, chatService: chat)

        await vm.joinChat()

        #expect(vm.hasJoined)
        #expect(chat.joinChatCalled)
        #expect(vm.errorMessage == nil)
    }

    @Test func joinChatDoesNothingWhenAlreadyJoined() async {
        let auth = authenticatedAuth()
        let chat = MockChatService()
        let vm = makeVM(authService: auth, chatService: chat)

        await vm.joinChat()
        chat.joinChatCalled = false // reset

        await vm.joinChat() // second call should be a no-op
        #expect(chat.joinChatCalled == false)
    }

    @Test func joinChatSetsErrorOnFailure() async {
        let auth = authenticatedAuth()
        let chat = MockChatService()
        chat.errorToThrow = PingItError.firestoreWriteFailed(underlying: URLError(.notConnectedToInternet))
        let vm = makeVM(authService: auth, chatService: chat)

        await vm.joinChat()

        #expect(vm.hasJoined == false)
        #expect(vm.errorMessage != nil)
    }

    // MARK: - leaveChat

    @Test func leaveChatSucceeds() async {
        let auth = authenticatedAuth()
        let chat = MockChatService()
        let vm = makeVM(authService: auth, chatService: chat)

        await vm.joinChat()
        await vm.leaveChat()

        #expect(vm.hasJoined == false)
        #expect(chat.leaveChatCalled)
    }

    // MARK: - Email verification gate

    @Test("Unverified email prevents sending messages")
    func unverifiedEmailCannotSendMessage() async {
        let mockAuth = MockAuthService()
        mockAuth.currentUser = MockAuthUser(uid: "user1", isEmailVerified: false)
        mockAuth.isEmailVerified = false
        let mockChat = MockChatService()

        let vm = ChatViewModel(chatId: "chat1", pingId: "ping1")
        vm.configure(authService: mockAuth, chatService: mockChat, contentModerationService: MockContentModerationService())
        vm.messageText = "Hello"

        await vm.sendMessage()

        #expect(vm.errorMessage != nil)
        #expect(mockChat.sendMessageCalled == false)
    }

    // MARK: - sendMessage

    @Test func sendMessageSucceeds() async {
        let auth = authenticatedAuth()
        let chat = MockChatService()
        let vm = makeVM(authService: auth, chatService: chat)
        vm.messageText = "Hey there!"

        await vm.sendMessage()

        #expect(chat.sendMessageCalled)
        #expect(vm.messageText == "")
        #expect(vm.errorMessage == nil)
    }

    @Test func sendMessageSetsErrorOnFailure() async {
        let auth = authenticatedAuth()
        let chat = MockChatService()
        chat.errorToThrow = PingItError.firestoreWriteFailed(underlying: URLError(.notConnectedToInternet))
        let vm = makeVM(authService: auth, chatService: chat)
        vm.messageText = "Hey there!"

        await vm.sendMessage()

        #expect(vm.errorMessage != nil)
    }

    // MARK: - Blocking filter

    @Test("Blocked user messages are filtered from chat")
    func blockedUserMessagesFiltered() async {
        let mockAuth = MockAuthService()
        mockAuth.currentUser = MockAuthUser(uid: "user1", isEmailVerified: true)
        mockAuth.isEmailVerified = true
        let mockChat = MockChatService()
        let mockBlockService = MockBlockService()
        mockBlockService.blockedUserIds = ["blocked_user"]

        let vm = ChatViewModel(chatId: "chat1", pingId: "ping1")
        vm.configure(authService: mockAuth, chatService: mockChat, contentModerationService: MockContentModerationService(), blockService: mockBlockService)

        let normalMessage = ChatMessage(chatId: "chat1", senderId: "user2", text: "Hi")
        let blockedMessage = ChatMessage(chatId: "chat1", senderId: "blocked_user", text: "You cant see me")
        mockChat.messagesToReturn = [normalMessage, blockedMessage]

        await vm.loadInitialMessages()

        #expect(vm.messages.count == 1)
        #expect(vm.messages.first?.text == "Hi")
    }

    // MARK: - Reactions

    @Test func toggleReactionCallsService() async {
        let auth = authenticatedAuth()
        let chat = MockChatService()
        let analytics = MockAnalyticsService()
        let vm = ChatViewModel(chatId: "chat-1", pingId: "ping-1")
        vm.configure(authService: auth, chatService: chat, analyticsService: analytics)

        await vm.toggleReaction(on: "msg-1", emoji: "👍")

        #expect(chat.toggleReactionCalled)
        #expect(chat.lastReactionEmoji == "👍")
        #expect(chat.lastReactionMessageId == "msg-1")
        #expect(analytics.loggedEvents.contains { $0.name == AnalyticsService.EventName.reactionToggled })
    }

    @Test func toggleReactionSetsErrorOnFailure() async {
        let auth = authenticatedAuth()
        let chat = MockChatService()
        chat.errorToThrow = PingItError.reactionFailed(underlying: URLError(.notConnectedToInternet))
        let vm = makeVM(authService: auth, chatService: chat)

        await vm.toggleReaction(on: "msg-1", emoji: "❤️")

        #expect(vm.errorMessage != nil)
    }

    // MARK: - Location Sharing

    @Test func sendLocationMessageSucceeds() async {
        let auth = authenticatedAuth()
        let chat = MockChatService()
        let analytics = MockAnalyticsService()
        let vm = ChatViewModel(chatId: "chat-1", pingId: "ping-1")
        vm.configure(authService: auth, chatService: chat, analyticsService: analytics)

        await vm.sendLocationMessage(latitude: 46.77, longitude: 23.62, locationName: "Test Location")

        #expect(chat.sendMessageCalled)
        #expect(chat.lastSentMessage?.messageType == Constants.MessageType.location)
        #expect(chat.lastSentMessage?.latitude == 46.77)
        #expect(chat.lastSentMessage?.longitude == 23.62)
        #expect(analytics.loggedEvents.contains { $0.name == AnalyticsService.EventName.locationShared })
    }

    @Test func sendLocationMessageBlockedWhenUnverified() async {
        let mockAuth = MockAuthService()
        mockAuth.currentUser = MockAuthUser(uid: "user1", isEmailVerified: false)
        mockAuth.isEmailVerified = false
        let mockChat = MockChatService()
        let vm = ChatViewModel(chatId: "chat-1", pingId: "ping-1")
        vm.configure(authService: mockAuth, chatService: mockChat)

        await vm.sendLocationMessage(latitude: 46.77, longitude: 23.62, locationName: nil)

        #expect(vm.errorMessage != nil)
        #expect(mockChat.sendMessageCalled == false)
    }

    // MARK: - Content Moderation

    @Test("Moderated text prevents sending message")
    func moderatedTextBlocksMessageSending() async {
        let mockAuth = MockAuthService()
        mockAuth.currentUser = MockAuthUser(uid: "user1", isEmailVerified: true)
        mockAuth.isEmailVerified = true
        let mockChat = MockChatService()
        let mockModeration = MockContentModerationService()
        mockModeration.resultToReturn = .blocked(reason: "Violates community guidelines.")

        let vm = ChatViewModel(chatId: "chat1", pingId: "ping1")
        vm.configure(authService: mockAuth, chatService: mockChat, contentModerationService: mockModeration)
        vm.messageText = "Bad word"

        await vm.sendMessage()

        #expect(vm.errorMessage != nil)
        #expect(mockModeration.checkCalled == true)
        #expect(mockChat.sendMessageCalled == false)
    }
}
