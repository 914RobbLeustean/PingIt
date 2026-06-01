import SwiftUI

struct PingItToggle: View {
    @Binding var isOn: Bool
    var accessibilityLabel: String? = nil

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? Color.pingLive : Color.pingSurfaceElevated)
                    .overlay(
                        Capsule()
                            .strokeBorder(isOn ? Color.pingLive : Color.pingBorder, lineWidth: 1)
                    )

                Circle()
                    .fill(Color.white)
                    .frame(width: 22, height: 22)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    .padding(.horizontal, 3)
            }
            .frame(width: 48, height: 28)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isOn)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel ?? "Toggle")
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityAddTraits(.isButton)
    }
}
