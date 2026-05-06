import Foundation

struct ChatJoinResult: Equatable, Sendable {
    let participantId: String
    let participantCount: Int
}

protocol ChatServicing {
    func sendMessage(_ message: ChatMessage) async throws
    func joinChatIfNeeded(chatId: String) async throws -> ChatJoinResult
    func leaveChat(chatId: String) async throws
    func createChat(pingId: String) async throws -> String
    func deleteChat(id: String) async throws
    func fetchMessages(chatId: String, before: Date?, limit: Int) async throws -> [ChatMessage]
    func observeMessages(
        chatId: String,
        onUpdate: @escaping @Sendable (Result<[ChatMessage], Error>) -> Void
    ) -> ListenerHandle
    func observeNewMessages(
        chatId: String,
        after: Date,
        onUpdate: @escaping @Sendable (Result<[ChatMessage], Error>) -> Void
    ) -> ListenerHandle
}
