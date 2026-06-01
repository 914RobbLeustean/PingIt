import SwiftUI

struct SettingsSection<Content: View>: View {
    let title: String?
    let isDestructive: Bool
    @ViewBuilder var content: () -> Content

    init(_ title: String? = nil, isDestructive: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.isDestructive = isDestructive
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title.uppercased())
                    .font(.dmSans(.semiBold, size: 11, relativeTo: .caption2))
                    .tracking(0.8)
                    .foregroundStyle(Color.pingTextSecondary)
                    .padding(.leading, 4)
            }

            VStack(spacing: 0) {
                content()
            }
            .background(Color.pingSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
            .clipShape(.rect(cornerRadius: 20))
        }
        .padding(.horizontal, 20)
    }

    private var borderColor: Color {
        isDestructive ? Color.pingHot.opacity(0.2) : Color.pingBorder
    }
}
