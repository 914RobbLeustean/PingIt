import Observation
@testable import PingIt

@Observable
@MainActor
final class MockAnalyticsService: AnalyticsServicing {
    private(set) var loggedEvents: [(name: String, parameters: [String: Any]?)] = []
    private(set) var lastUserId: String?
    private(set) var setUserIdCalled = false

    func logEvent(_ name: String, parameters: [String: Any]?) {
        loggedEvents.append((name: name, parameters: parameters))
    }

    func setUserId(_ userId: String?) {
        lastUserId = userId
        setUserIdCalled = true
    }
}
