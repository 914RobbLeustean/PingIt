import Observation
@testable import PingIt

@Observable
@MainActor
final class MockRateLimitService: RateLimitServicing {
    var pingResult: RateLimitResult = .allowed
    var messageResult: RateLimitResult = .allowed
    var recordPingCreationCalled = false
    var recordMessageSentCalled = false

    func canCreatePing() -> RateLimitResult {
        pingResult
    }

    func canSendMessage() -> RateLimitResult {
        messageResult
    }

    func recordPingCreation() {
        recordPingCreationCalled = true
    }

    func recordMessageSent() {
        recordMessageSentCalled = true
    }
}
