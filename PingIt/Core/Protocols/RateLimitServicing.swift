import Foundation

enum RateLimitResult: Sendable {
    case allowed
    case limited(retryAfter: TimeInterval)
}

protocol RateLimitServicing {
    func canCreatePing() -> RateLimitResult
    func canSendMessage() -> RateLimitResult
    func recordPingCreation()
    func recordMessageSent()
}
