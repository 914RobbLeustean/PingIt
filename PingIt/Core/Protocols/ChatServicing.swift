import Foundation

protocol ChatServicing {
    func sendMessage(_ message: ChatMessage) async throws
    func joinChatIfNeeded(chatId: String, userId: String) async throws -> String
    func leaveChat(participantId: String) async throws
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
