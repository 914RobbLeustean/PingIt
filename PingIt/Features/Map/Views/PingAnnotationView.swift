import SwiftUI

struct PingAnnotationView: View {
    let ping: Ping
    let isHot: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: handleTap) {
            VStack(spacing: 4) {
                Image(systemName: isHot ? "flame.circle.fill" : "mappin.circle.fill")
                    .font(isHot ? .title : .title2)
                    .foregroundStyle(.white)
                    .background {
                        Circle()
                            .fill(pinGradient)
                            .frame(width: isHot ? 42 : 36, height: isHot ? 42 : 36)
                    }
                    .shadow(color: isHot ? .red.opacity(0.5) : .clear, radius: isHot ? 6 : 0)

                Text(ping.expiresAt.countdownDescription)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ping: \(ping.text), \(ping.expiresAt.countdownDescription)\(isHot ? ", trending" : "")")
    }

    private var pinGradient: AnyGradient {
        isHot ? Color.red.gradient : Color.orange.gradient
    }

    private func handleTap() {
        onTap()
    }
}
