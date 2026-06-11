import SwiftUI

struct PrimaryPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.syne(.extraBold, size: 16))
            .tracking(-0.3)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.pingAccent, in: .rect(cornerRadius: 28))
            .shadow(color: Color.pingAccent.opacity(0.35), radius: 16, x: 0, y: 0)
            .shadow(color: .black.opacity(0.40), radius: 12, x: 0, y: 8)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
