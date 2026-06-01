import Foundation

struct BoostPingResult: Equatable, Sendable {
    let boostCount: Int
    let didBoost: Bool
}

protocol PingServicing {
    func createPing(_ ping: Ping) async throws -> String
    func fetchPing(id: String) async throws -> Ping
    func deletePing(id: String) async throws
    /// Creates a ping and its associated chat atomically.
    func createPingWithChat(_ ping: Ping) async throws
    func observeActivePings(
        onUpdate: @escaping @Sendable (Result<[Ping], Error>) -> Void
    ) -> ListenerHandle
    func observePing(
        id: String,
        onUpdate: @escaping @Sendable (Ping?) -> Void
    ) -> ListenerHandle
    func createPingWithChat(_ ping: Ping, pingId: String) async throws
    func uploadPingImage(pingId: String, imageData: Data) async throws -> String
    func boostPing(pingId: String) async throws -> BoostPingResult
    func hasUserBoostedPing(pingId: String, userId: String) async throws -> Bool
    func fetchPings(byCreatorId creatorId: String) async throws -> [Ping]
}
