import Observation
@testable import PingIt

@Observable
@MainActor
final class MockCrashReportingService: CrashReportingServicing {
    private(set) var lastUserId: String?
    private(set) var setUserIdCalled = false
    private(set) var recordedErrors: [Error] = []

    func setUserId(_ userId: String?) {
        lastUserId = userId
        setUserIdCalled = true
    }

    func record(error: Error) {
        recordedErrors.append(error)
    }
}
