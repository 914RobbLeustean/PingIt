import Testing
@testable import PingIt

@Suite("Content Moderation")
@MainActor
struct ContentModerationTests {

    private func isBlocked(_ result: ContentModerationResult) -> Bool {
        if case .blocked = result { return true }
        return false
    }

    private func isAllowed(_ result: ContentModerationResult) -> Bool {
        if case .allowed = result { return true }
        return false
    }

    @Test func profanityIsBlocked() {
        let service = ContentModerationService()
        #expect(isBlocked(service.check("fuck this")))
    }

    @Test func cleanTextIsAllowed() {
        let service = ContentModerationService()
        #expect(isAllowed(service.check("Let's meet at the park for a study session!")))
    }

    @Test func blockedWordDetectedCaseInsensitive() {
        let service = ContentModerationService()
        #expect(isBlocked(service.check("You are a RETARD")))
    }

    @Test func romanianProfanityDetected() {
        let service = ContentModerationService()
        #expect(isBlocked(service.check("du-te in muie")))
    }
}
