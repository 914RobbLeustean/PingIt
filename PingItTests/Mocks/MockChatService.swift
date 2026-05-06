import Foundation
import Observation
@testable import PingIt

@Observable
@MainActor
final class MockChatService: ChatServicing {
    var errorToThrow: Error?
    var joinResult = ChatJoinResult(participantId: "mock-participant-id", participantCount: 1)

    var sendMessageCalled = false
    var joinChatCalled = false
    var leaveChatCalled = false
    private(set) var removeCalled = false
    var lastSentMessage: ChatMessage?
    var messagesToReturn: [ChatMessage] = []

    private(set) var messagesCallback: (@Sendable (Result<[ChatMessage], Error>) -> Void)?
    private(set) var newMessagesCallback: (@Sendable (Result<[ChatMessage], Error>) -> Void)?

    func sendMessage(_ message: ChatMessage) async throws {
        sendMessageCalled = true
        lastSentMessage = message
        if let error = errorToThrow { throw error }
    }

    func joinChatIfNeeded(chatId: String) async throws -> ChatJoinResult {
        joinChatCalled = true
        if let error = errorToThrow { throw error }
        return joinResult
    }

    func leaveChat(chatId: String) async throws {
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

    func fetchMessages(chatId: String, before: Date?, limit: Int) async throws -> [ChatMessage] {
        if let error = errorToThrow { throw error }
        if let before {
            return messagesToReturn.filter { ($0.createdAt ?? .distantFuture) < before }
                .suffix(limit).map { $0 }
        }
        return Array(messagesToReturn.suffix(limit))
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

    func observeNewMessages(
        chatId: String,
        after: Date,
        onUpdate: @escaping @Sendable (Result<[ChatMessage], Error>) -> Void
    ) -> ListenerHandle {
        newMessagesCallback = onUpdate
        return ListenerHandle { [weak self] in
            self?.removeCalled = true
        }
    }

    func simulateNewMessage(_ message: ChatMessage) {
        newMessagesCallback?(.success([message]))
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
