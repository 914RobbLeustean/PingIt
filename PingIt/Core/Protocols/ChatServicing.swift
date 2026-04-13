protocol ChatServicing {
    func sendMessage(_ message: ChatMessage) async throws
    func joinChatIfNeeded(chatId: String, userId: String) async throws -> String
    func leaveChat(participantId: String) async throws
    func createChat(pingId: String) async throws -> String
    func deleteChat(id: String) async throws
    func observeMessages(
        chatId: String,
        onUpdate: @escaping @Sendable (Result<[ChatMessage], Error>) -> Void
    ) -> ListenerHandle
}
