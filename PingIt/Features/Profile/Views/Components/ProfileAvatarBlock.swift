import SwiftUI

struct ProfileAvatarBlock: View {
    let initial: String
    let username: String
    let email: String
    let profileImageUrl: String?
    let isUploading: Bool
    let onEditTapped: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            avatarWithEditButton

            Text("@\(username)")
                .font(.syne(.extraBold, size: 22, relativeTo: .title2))
                .tracking(-0.3)
                .foregroundStyle(Color.pingTextPrimary)

            Text(email)
                .font(.dmSans(.regular, size: 13, relativeTo: .footnote))
                .foregroundStyle(Color.pingTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 28)
    }

    private var avatarWithEditButton: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarImage

            Button("Edit Photo", systemImage: "pencil", action: onEditTapped)
                .labelStyle(.iconOnly)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.black)
                .frame(width: 28, height: 28)
                .background(Color.pingAccent)
                .clipShape(.circle)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Profile photo, \(username)")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Change your profile photo")
    }

    @ViewBuilder
    private var avatarImage: some View {
        ZStack {
            if let urlString = profileImageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    initialCircle
                }
                .frame(width: 86, height: 86)
                .clipShape(.circle)
                .overlay(
                    Circle()
                        .strokeBorder(Color.pingAccent.opacity(0.4), lineWidth: 3)
                )
                .shadow(color: Color.pingAccent.opacity(0.2), radius: 12)
            } else {
                initialCircle
            }

            if isUploading {
                ProgressView()
                    .tint(.white)
                    .frame(width: 86, height: 86)
                    .background(.ultraThinMaterial)
                    .clipShape(.circle)
            }
        }
    }

    private var initialCircle: some View {
        Text(initial)
            .font(.syne(.extraBold, size: 36))
            .foregroundStyle(.white)
            .frame(width: 86, height: 86)
            .background(Color.pingAccent)
            .clipShape(.circle)
            .overlay(
                Circle()
                    .strokeBorder(Color.pingAccent.opacity(0.4), lineWidth: 3)
            )
            .shadow(color: Color.pingAccent.opacity(0.2), radius: 12)
    }
}
