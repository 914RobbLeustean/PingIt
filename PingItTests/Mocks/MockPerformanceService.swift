import Observation
@testable import PingIt

@Observable
@MainActor
final class MockPerformanceService: PerformanceServicing {
    private(set) var startedTraces: [String] = []

    nonisolated func startTrace(name: String) -> PerformanceTrace? {
        MockPerformanceTrace(name: name)
    }
}

struct MockPerformanceTrace: PerformanceTrace {
    let name: String
    private(set) var attributes: [String: Int64] = [:]

    func setValue(_ value: Int64, forAttribute attribute: String) {}
    func stop() {}
}
