import SwiftUI

struct FeedLivePulse: View {
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Color.pingLive)
                .frame(width: 7, height: 7)
                .scaleEffect(isPulsing ? 1.3 : 1.0)
                .opacity(isPulsing ? 0.6 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isPulsing)

            Text("Live")
                .font(.dmSans(.semiBold, size: 11, relativeTo: .caption2))
                .tracking(0.5)
                .textCase(.uppercase)
                .foregroundStyle(Color.pingLive)
        }
        .onAppear { isPulsing = true }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Live feed")
    }
}
