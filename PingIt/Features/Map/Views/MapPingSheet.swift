import SwiftUI

struct MapPingSheet: View {
    let ping: Ping
    let creator: User?
    let onJoinChat: () -> Void
    let onViewDetails: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SheetAuthorRow(ping: ping, creator: creator)
                .padding(.bottom, 10)

            SheetTitle(ping: ping)
                .padding(.bottom, 6)

            if let description = ping.description,
               !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                SheetDescription(text: description)
                    .padding(.bottom, 14)
            } else {
                Spacer()
                    .frame(height: 8)
            }

            SheetStatsRow(ping: ping)
                .padding(.bottom, 18)

            SheetButtonRow(onJoinChat: onJoinChat, onViewDetails: onViewDetails)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .presentationDetents([.height(280), .medium, .large])
        .presentationBackgroundInteraction(.enabled(upThrough: .height(280)))
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }
}

// MARK: - Author Row

private struct SheetAuthorRow: View {
    let ping: Ping
    let creator: User?

    // A private creator must stay anonymous everywhere — avatar included.
    private var hideIdentity: Bool {
        creator?.isPrivateProfile == true
    }

    var body: some View {
        HStack {
            HStack(spacing: 9) {
                SheetAvatar(creator: hideIdentity ? nil : creator, size: 32)

                Text("@\(displayName)")
                    .font(.dmSans(.medium, size: 13, relativeTo: .footnote))
                    .foregroundStyle(Color.pingTextSecondary)
            }

            Spacer()

            SheetUrgencyLabel(expiresAt: ping.expiresAt)
        }
        .accessibilityElement(children: .combine)
    }

    private var displayName: String {
        if let creator, !creator.isPrivateProfile {
            return creator.username
        }
        return "anonymous"
    }
}

// MARK: - Avatar

private struct SheetAvatar: View {
    let creator: User?
    let size: CGFloat

    var body: some View {
        if let urlString = creator?.profileImageUrl, let url = URL(string: urlString) {
            CachedAsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                avatarPlaceholder
            }
            .frame(width: size, height: size)
            .clipShape(.circle)
        } else {
            avatarPlaceholder
        }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(avatarColor)
            .frame(width: size, height: size)
            .overlay(
                Text(initial)
                    .font(.syne(.extraBold, size: size * 0.4))
                    .foregroundStyle(.white)
            )
    }

    private var initial: String {
        let name = creator?.username ?? "?"
        return String(name.prefix(1)).uppercased()
    }

    private var avatarColor: Color {
        guard let name = creator?.username else { return .pingTextSecondary }
        var hash = 0
        for char in name.unicodeScalars {
            hash = Int(char.value) &+ (hash &<< 6) &+ (hash &<< 16) &- hash
        }
        let hue = Double(abs(hash) % 360) / 360.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.8)
    }
}

// MARK: - Urgency Label

private struct SheetUrgencyLabel: View {
    let expiresAt: Date

    private var urgency: PingUrgency {
        .from(expiresAt: expiresAt)
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.system(size: 12))
            Text(expiresAt.countdownDescription)
                .font(.dmSans(.medium, size: 13, relativeTo: .footnote))
        }
        .foregroundStyle(urgency.color)
    }
}

// MARK: - Title

private struct SheetTitle: View {
    let ping: Ping

    var body: some View {
        Text(titleText)
            .font(.syne(.extraBold, size: 20, relativeTo: .title3))
            .foregroundStyle(Color.pingTextPrimary)
            .lineSpacing(2)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var titleText: String {
        if let category = ping.category.flatMap(PingCategory.init(rawValue:)) {
            return "\(category.emoji)  \(ping.text)"
        }
        return ping.text
    }
}

// MARK: - Description

private struct SheetDescription: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.dmSans(.regular, size: 13, relativeTo: .footnote))
            .foregroundStyle(Color.pingTextSecondary)
            .lineSpacing(4)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Stats Row

private struct SheetStatsRow: View {
    let ping: Ping

    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 4) {
                Image(systemName: "flame")
                    .font(.system(size: 13))
                Text("\(ping.boostCount) boosts")
                    .font(.dmSans(.regular, size: 13, relativeTo: .footnote))
            }
            .foregroundStyle(ping.boostCount > 0 ? Color.pingAccent : .pingTextSecondary)

            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 13))
                Text("\(ping.attendingCount) going")
                    .font(.dmSans(.regular, size: 13, relativeTo: .footnote))
            }
            .foregroundStyle(ping.attendingCount > 0 ? Color.pingLive : .pingTextSecondary)

            HStack(spacing: 4) {
                Image(systemName: "person.2")
                    .font(.system(size: 13))
                Text("\(ping.participantCount) in chat")
                    .font(.dmSans(.regular, size: 13, relativeTo: .footnote))
            }
            .foregroundStyle(Color.pingTextSecondary)

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Stats")
        .accessibilityValue("\(ping.boostCount) boosts, \(ping.attendingCount) going, \(ping.participantCount) in chat")
    }
}

// MARK: - Button Row

private struct SheetButtonRow: View {
    let onJoinChat: () -> Void
    let onViewDetails: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onJoinChat) {
                HStack(spacing: 7) {
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 14))
                    Text("JOIN CHAT")
                        .font(.syne(.extraBold, size: 14))
                        .tracking(-0.3)
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.pingAccent)
                .clipShape(.capsule)
                .shadow(color: Color.pingAccent.opacity(0.3), radius: 10)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Join chat")

            Button(action: onViewDetails) {
                Text("Details")
                    .font(.dmSans(.medium, size: 14, relativeTo: .body))
                    .foregroundStyle(Color.pingTextPrimary)
                    .frame(width: 90, height: 48)
                    .background(Color.pingSurfaceElevated)
                    .clipShape(.capsule)
                    .overlay(
                        Capsule()
                            .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("View ping details")
        }
    }
}
