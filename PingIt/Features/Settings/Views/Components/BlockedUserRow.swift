import SwiftUI

struct BlockedUserRow: View {
    let username: String
    let avatarURL: URL?
    let onUnblock: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            avatar
            Text(username)
                .font(.dmSans(.semiBold, size: 15, relativeTo: .body))
                .foregroundStyle(Color.pingTextPrimary)
                .lineLimit(1)

            Spacer(minLength: 0)

            Button("Unblock", action: onUnblock)
                .buttonStyle(UnblockPillStyle())
        }
        .padding(.horizontal, 18)
        .frame(minHeight: 64)
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(Color.pingSurfaceElevated)
                .overlay(
                    Circle()
                        .strokeBorder(Color.pingBorder, lineWidth: 1)
                )

            if let avatarURL {
                CachedAsyncImage(url: avatarURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    placeholderGlyph
                }
            } else {
                placeholderGlyph
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(.circle)
        .accessibilityHidden(true)
    }

    private var placeholderGlyph: some View {
        Image(systemName: "person.fill")
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(Color.pingTextSecondary)
    }
}

private struct UnblockPillStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.dmSans(.semiBold, size: 13))
            .foregroundStyle(Color.pingAccent)
            .padding(.horizontal, 14)
            .frame(height: 32)
            .background(
                Capsule()
                    .fill(Color.pingAccent.opacity(0.12))
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.pingAccent.opacity(0.45), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
