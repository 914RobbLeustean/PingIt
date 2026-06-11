import Foundation

enum PingCategory: String, CaseIterable, Sendable {
    case sports
    case study
    case social
    case music
    case food
    case skate
    case chill
    case gaming
    case art

    var label: String {
        switch self {
        case .sports:  "Sports"
        case .study:   "Study"
        case .social:  "Social"
        case .music:   "Music"
        case .food:    "Food"
        case .skate:   "Skate"
        case .chill:   "Chill"
        case .gaming:  "Gaming"
        case .art:     "Art"
        }
    }

    var emoji: String {
        switch self {
        case .sports:  "🏀"
        case .study:   "📚"
        case .social:  "🍻"
        case .music:   "🎸"
        case .food:    "🍕"
        case .skate:   "🛹"
        case .chill:   "☕"
        case .gaming:  "🎮"
        case .art:     "🎨"
        }
    }
}
