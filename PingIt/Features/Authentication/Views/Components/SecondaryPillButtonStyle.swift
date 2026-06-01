import SwiftUI

struct SecondaryPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.dmSans(.medium, size: 16))
            .foregroundStyle(Color.pingTextPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.pingSurface, in: .rect(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .strokeBorder(Color.pingBorder, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
