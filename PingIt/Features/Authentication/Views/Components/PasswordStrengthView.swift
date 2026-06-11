import SwiftUI

struct PasswordStrengthView: View {
    let result: PasswordValidator.Result

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            strengthBar
            rulesList
        }
    }

    private var strengthBar: some View {
        HStack(spacing: 4) {
            ForEach(0..<4) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(segmentColor(at: index))
                    .frame(height: 6)
                    .animation(.easeInOut(duration: 0.2), value: result.strength)
            }
        }
    }

    private var rulesList: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(result.rules) { rule in
                HStack(spacing: 6) {
                    Image(systemName: rule.isMet ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 12))
                        .foregroundStyle(rule.isMet ? Color.pingLive : Color.pingTextSecondary)
                    Text(rule.label)
                        .font(.dmSans(.regular, size: 12, relativeTo: .caption))
                        .foregroundStyle(rule.isMet ? Color.pingTextPrimary : Color.pingTextSecondary)
                }
            }
        }
    }

    private func segmentColor(at index: Int) -> Color {
        switch result.strength {
        case .empty:
            return Color.pingBorder
        case .weak:
            return index < 1 ? Color.pingHot : Color.pingBorder
        case .moderate:
            return index < 3 ? Color.pingAccent : Color.pingBorder
        case .strong:
            return Color.pingLive
        }
    }
}
