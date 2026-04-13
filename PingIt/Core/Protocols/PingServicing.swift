protocol PingServicing {
    func createPing(_ ping: Ping) async throws -> String
    func fetchPing(id: String) async throws -> Ping
    func deletePing(id: String) async throws
    /// Creates a ping and its associated chat atomically.
    func createPingWithChat(_ ping: Ping) async throws
    func deletePingAndChat(pingId: String, chatId: String?) async throws
    func observeActivePings(
        onUpdate: @escaping @Sendable (Result<[Ping], Error>) -> Void
    ) -> ListenerHandle
}
