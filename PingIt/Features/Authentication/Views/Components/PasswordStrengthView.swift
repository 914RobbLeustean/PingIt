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
        GeometryReader { proxy in
            HStack(spacing: 4) {
                ForEach(0..<4) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(segmentColor(at: index))
                        .animation(.easeInOut(duration: 0.2), value: result.strength)
                }
            }
            .frame(width: proxy.size.width, height: 6)
        }
        .frame(height: 6)
    }

    private var rulesList: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(result.rules) { rule in
                HStack(spacing: 6) {
                    Image(systemName: rule.isMet ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(rule.isMet ? .green : .secondary)
                        .imageScale(.small)
                    Text(rule.label)
                        .font(.caption)
                        .foregroundStyle(rule.isMet ? .primary : .secondary)
                }
            }
        }
    }

    private func segmentColor(at index: Int) -> Color {
        switch result.strength {
        case .empty:
            return Color(.systemGray5)
        case .weak:
            return index < 1 ? .red : Color(.systemGray5)
        case .moderate:
            return index < 3 ? .orange : Color(.systemGray5)
        case .strong:
            return .green
        }
    }
}
