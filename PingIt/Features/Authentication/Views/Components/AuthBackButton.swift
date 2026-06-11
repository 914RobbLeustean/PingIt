import SwiftUI

struct AuthBackButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.pingTextPrimary)
                .frame(width: 38, height: 38)
                .background(Color.pingSurface, in: .circle)
                .overlay(
                    Circle().strokeBorder(Color.pingBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
    }
}
