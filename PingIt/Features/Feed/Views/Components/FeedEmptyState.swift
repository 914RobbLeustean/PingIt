import SwiftUI

struct FeedEmptyState: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("\u{1F4CD}")
                .font(.system(size: 40))

            Text("Nothing happening yet.")
                .font(.syne(.bold, size: 18, relativeTo: .title3))
                .foregroundStyle(Color.pingTextPrimary)

            Text("Drop one and start something.")
                .font(.dmSans(.regular, size: 14, relativeTo: .subheadline))
                .foregroundStyle(Color.pingTextSecondary)
        }
        .padding(.top, 80)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
