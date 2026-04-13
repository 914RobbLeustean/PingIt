import Observation
@testable import PingIt

@Observable
@MainActor
final class MockPingService: PingServicing {
    var pingToReturn: Ping?
    var errorToThrow: Error?

    var createPingCalled = false
    var createPingWithChatCalled = false
    var deletePingAndChatCalled = false
    private(set) var removeCalled = false

    private(set) var activePingsCallback: (@Sendable (Result<[Ping], Error>) -> Void)?

    func createPing(_ ping: Ping) async throws -> String {
        createPingCalled = true
        if let error = errorToThrow { throw error }
        return "mock-ping-id"
    }

    func fetchPing(id: String) async throws -> Ping {
        if let error = errorToThrow { throw error }
        return pingToReturn ?? Ping(
            creatorId: "user1",
            text: "Mock ping",
            location: .init(latitude: 46.77, longitude: 23.62),
            geohash: "",
            expiresAt: .distantFuture,
            status: .active
        )
    }

    func deletePing(id: String) async throws {
        if let error = errorToThrow { throw error }
    }

    func createPingWithChat(_ ping: Ping) async throws {
        createPingWithChatCalled = true
        if let error = errorToThrow { throw error }
    }

    func deletePingAndChat(pingId: String, chatId: String?) async throws {
        deletePingAndChatCalled = true
        if let error = errorToThrow { throw error }
    }

    func observeActivePings(
        onUpdate: @escaping @Sendable (Result<[Ping], Error>) -> Void
    ) -> ListenerHandle {
        activePingsCallback = onUpdate
        return ListenerHandle { [weak self] in
            self?.removeCalled = true
        }
    }

    /// Simulates a Firestore snapshot arriving with the given pings.
    func simulateUpdate(pings: [Ping]) {
        activePingsCallback?(.success(pings))
    }

    /// Simulates a Firestore snapshot error.
    func simulateError(_ error: Error) {
        activePingsCallback?(.failure(error))
    }
}
