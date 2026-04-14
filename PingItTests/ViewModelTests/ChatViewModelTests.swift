import Testing
@testable import PingIt

@Suite("ChatViewModel")
@MainActor
struct ChatViewModelTests {

    // MARK: - Helpers

    private func makeVM(
        authService: MockAuthService = MockAuthService(),
        chatService: MockChatService = MockChatService(),
        contentModerationService: MockContentModerationService = MockContentModerationService(),
        chatId: String = "chat-1",
        pingId: String = "ping-1"
    ) -> ChatViewModel {
        let vm = ChatViewModel(chatId: chatId, pingId: pingId)
        vm.configure(authService: authService, chatService: chatService, contentModerationService: contentModerationService)
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

    // MARK: - startObserving / stopObserving

    @Test func startObservingAttachesListener() {
        let chat = MockChatService()
        let vm = makeVM(chatService: chat)
        vm.startObserving()
        #expect(chat.messagesCallback != nil)
    }

    @Test func stopObservingCallsRemoveOnListener() {
        let chat = MockChatService()
        let vm = makeVM(chatService: chat)
        vm.startObserving()
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

        await vm.joinChat() // sets participantDocId
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
