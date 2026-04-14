import Observation
@testable import PingIt

@Observable
@MainActor
final class MockContentModerationService: ContentModeratingServicing {
    var resultToReturn: ContentModerationResult = .allowed
    var checkCalled = false
    var lastCheckedText: String?

    func check(_ text: String) -> ContentModerationResult {
        checkCalled = true
        lastCheckedText = text
        return resultToReturn
    }
}
