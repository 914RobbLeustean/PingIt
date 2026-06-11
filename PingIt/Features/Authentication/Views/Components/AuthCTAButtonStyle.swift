import SwiftUI

struct AuthCTAButtonStyle: ButtonStyle {
    let isEnabled: Bool
    var isLoading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.syne(.extraBold, size: 16))
            .tracking(-0.3)
            .foregroundStyle(isEnabled ? Color.black : Color.pingTextSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 27)
                    .fill(isEnabled ? Color.pingAccent : Color.pingSurfaceElevated)
            )
            .shadow(
                color: isEnabled ? Color.pingAccent.opacity(0.35) : .clear,
                radius: 16, x: 0, y: 0
            )
            .opacity(isLoading ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed && isEnabled ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isEnabled)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
