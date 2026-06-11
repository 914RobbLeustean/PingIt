import Foundation

enum ContentModerationResult: Sendable {
    case allowed
    case blocked(reason: String)
}

protocol ContentModeratingServicing {
    func check(_ text: String) -> ContentModerationResult
}
