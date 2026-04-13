import Observation
@testable import PingIt

@Observable
@MainActor
final class MockChatService: ChatServicing {
    var errorToThrow: Error?
    var participantIdToReturn = "mock-participant-id"

    var sendMessageCalled = false
    var joinChatCalled = false
    var leaveChatCalled = false
    private(set) var removeCalled = false
    var lastSentMessage: ChatMessage?

    private(set) var messagesCallback: (@Sendable (Result<[ChatMessage], Error>) -> Void)?

    func sendMessage(_ message: ChatMessage) async throws {
        sendMessageCalled = true
        lastSentMessage = message
        if let error = errorToThrow { throw error }
    }

    func joinChatIfNeeded(chatId: String, userId: String) async throws -> String {
        joinChatCalled = true
        if let error = errorToThrow { throw error }
        return participantIdToReturn
    }

    func leaveChat(participantId: String) async throws {
        leaveChatCalled = true
        if let error = errorToThrow { throw error }
    }

    func createChat(pingId: String) async throws -> String {
        if let error = errorToThrow { throw error }
        return "mock-chat-id"
    }

    func deleteChat(id: String) async throws {
        if let error = errorToThrow { throw error }
    }

    func observeMessages(
        chatId: String,
        onUpdate: @escaping @Sendable (Result<[ChatMessage], Error>) -> Void
    ) -> ListenerHandle {
        messagesCallback = onUpdate
        return ListenerHandle { [weak self] in
            self?.removeCalled = true
        }
    }

    /// Simulates a Firestore snapshot arriving with the given messages.
    func simulateUpdate(messages: [ChatMessage]) {
        messagesCallback?(.success(messages))
    }

    /// Simulates a Firestore snapshot error.
    func simulateError(_ error: Error) {
        messagesCallback?(.failure(error))
    }
}
