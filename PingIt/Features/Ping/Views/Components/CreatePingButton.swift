import SwiftUI

struct CreatePingButton: View {
    let canCreate: Bool
    let isCreating: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [.clear, Color.pingSurface],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 32)
            .allowsHitTesting(false)

            Button(action: action) {
                Group {
                    if isCreating {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Text(canCreate ? "⚡ PING IT" : "Fill in the details")
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
            }
            .buttonStyle(CreatePingButtonStyle(isEnabled: canCreate))
            .disabled(!canCreate || isCreating)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }
}

struct CreatePingButtonStyle: ButtonStyle {
    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.syne(.extraBold, size: 18))
            .foregroundStyle(isEnabled ? Color.black : .pingTextSecondary)
            .background(isEnabled ? Color.pingAccent : .pingSurfaceElevated)
            .clipShape(.capsule)
            .shadow(
                color: isEnabled ? Color.pingAccent.opacity(0.35) : .clear,
                radius: 14, y: 4
            )
            .scaleEffect(configuration.isPressed && isEnabled ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isEnabled)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
