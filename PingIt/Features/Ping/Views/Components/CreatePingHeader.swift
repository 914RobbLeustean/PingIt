import SwiftUI

struct CreatePingHeader: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.12))
                .frame(width: 36, height: 4)
                .padding(.top, 14)
                .padding(.bottom, 16)

            HStack {
                Text("New Ping")
                    .font(.syne(.extraBold, size: 22, relativeTo: .title2))
                    .foregroundStyle(Color.pingTextPrimary)

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.pingTextSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color.pingSurfaceElevated)
                        .clipShape(.circle)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.pingBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}
