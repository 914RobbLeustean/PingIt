import SwiftUI

struct BlockedUsersEmptyState: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.pingSurface)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.pingBorder, lineWidth: 1)
                    )
                Image(systemName: systemImage)
                    .font(.system(size: 30, weight: .regular))
                    .foregroundStyle(Color.pingTextSecondary)
            }
            .frame(width: 88, height: 88)

            VStack(spacing: 6) {
                Text(title)
                    .font(.syne(.bold, size: 18, relativeTo: .title3))
                    .foregroundStyle(Color.pingTextPrimary)
                Text(message)
                    .font(.dmSans(.regular, size: 14, relativeTo: .footnote))
                    .foregroundStyle(Color.pingTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity)
    }
}
