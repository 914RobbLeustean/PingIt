import Foundation

@Observable
@MainActor
final class ContentModerationService: ContentModeratingServicing {
    private let blockedWords: [String]

    init() {
        guard let url = Bundle.main.url(forResource: "moderation_wordlist", withExtension: "txt"),
              let contents = try? String(contentsOf: url, encoding: .utf8) else {
            blockedWords = []
            return
        }
        blockedWords = contents
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    func check(_ text: String) -> ContentModerationResult {
        for word in blockedWords {
            if text.localizedStandardContains(word) {
                return .blocked(reason: "This message violates community guidelines.")
            }
        }
        return .allowed
    }
}
