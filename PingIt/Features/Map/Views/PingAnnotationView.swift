import SwiftUI

struct PingAnnotationView: View {
    let ping: Ping
    var onTap: () -> Void

    var body: some View {
        Button(action: handleTap) {
            VStack(spacing: 4) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .background {
                        Circle()
                            .fill(.orange.gradient)
                            .frame(width: 36, height: 36)
                    }

                Text(ping.expiresAt.countdownDescription)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ping: \(ping.text), \(ping.expiresAt.countdownDescription)")
    }

    private func handleTap() {
        onTap()
    }
}
