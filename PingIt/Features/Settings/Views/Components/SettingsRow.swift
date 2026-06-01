import SwiftUI

struct SettingsRow<Trailing: View>: View {
    let label: String
    let labelColor: Color
    let action: (() -> Void)?
    @ViewBuilder var trailing: () -> Trailing

    init(
        _ label: String,
        labelColor: Color = .pingTextPrimary,
        action: (() -> Void)? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.label = label
        self.labelColor = labelColor
        self.action = action
        self.trailing = trailing
    }

    var body: some View {
        if let action {
            Button(action: action) {
                rowContent
            }
            .buttonStyle(SettingsRowButtonStyle())
        } else {
            rowContent
        }
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.dmSans(.medium, size: 15, relativeTo: .body))
                .foregroundStyle(labelColor)

            Spacer(minLength: 0)

            trailing()
        }
        .padding(.horizontal, 18)
        .frame(minHeight: 52)
        .contentShape(.rect)
    }
}

extension SettingsRow where Trailing == SettingsChevron {
    init(
        _ label: String,
        labelColor: Color = .pingTextPrimary,
        action: (() -> Void)? = nil
    ) {
        self.init(label, labelColor: labelColor, action: action) {
            SettingsChevron()
        }
    }
}

struct SettingsChevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color.pingTextSecondary)
    }
}

private struct SettingsRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Color.white.opacity(configuration.isPressed ? 0.03 : 0)
            )
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
