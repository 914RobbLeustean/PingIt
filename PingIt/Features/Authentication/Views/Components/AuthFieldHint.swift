import SwiftUI

struct AuthFieldHint: View {
    enum Tone {
        case error
        case soft
        case success
    }

    let message: String
    let tone: Tone

    var body: some View {
        Text(message)
            .font(.dmSans(.regular, size: 12, relativeTo: .caption))
            .foregroundStyle(color)
            .padding(.horizontal, 4)
    }

    private var color: Color {
        switch tone {
        case .error:   return Color.pingHot
        case .soft:    return Color.pingTextSecondary
        case .success: return Color.pingAccent
        }
    }
}
