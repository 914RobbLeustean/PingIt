import SwiftUI

struct FeedHotBadge: View {
    var body: some View {
        Text("HOT")
            .font(.dmSans(.bold, size: 10, relativeTo: .caption2))
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color.pingHot)
            .clipShape(.capsule)
            .accessibilityLabel("Hot ping")
    }
}
