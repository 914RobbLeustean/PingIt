import SwiftUI

struct PingFeedCardView: View {
    let ping: Ping
    let creator: User?
    let distanceText: String?
    let urgency: PingUrgency
    let isHot: Bool

    var body: some View {
        HStack(spacing: 0) {
            UrgencyEdgeBar(urgency: urgency)

            VStack(alignment: .leading, spacing: 6) {
                AuthorRow(creator: creator, isHot: isHot)
                TitleRow(ping: ping)
                MetaRow(
                    ping: ping,
                    urgency: urgency,
                    distanceText: distanceText
                )
            }
            .padding(14)
            .padding(.leading, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.pingSurface)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isHot ? Color.pingHot.opacity(0.2) : .pingBorder,
                    lineWidth: 1
                )
        )
        .shadow(
            color: isHot ? Color.pingHot.opacity(0.08) : .clear,
            radius: 10
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Urgency Edge Bar

private struct UrgencyEdgeBar: View {
    let urgency: PingUrgency

    var body: some View {
        if urgency != .normal {
            Rectangle()
                .fill(urgency.color)
                .frame(width: 3)
        }
    }
}

// MARK: - Author Row

private struct AuthorRow: View {
    let creator: User?
    let isHot: Bool

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                CreatorAvatar(creator: creator, size: 26)

                Text("@\(displayName)")
                    .font(.dmSans(.medium, size: 12, relativeTo: .caption))
                    .foregroundStyle(Color.pingTextSecondary)
            }

            Spacer()

            if isHot {
                FeedHotBadge()
            }
        }
    }

    private var displayName: String {
        if let creator, !creator.isPrivateProfile {
            return creator.username
        }
        return "anonymous"
    }
}

// MARK: - Creator Avatar

private struct CreatorAvatar: View {
    let creator: User?
    let size: CGFloat

    var body: some View {
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

// MARK: - Title Row

private struct TitleRow: View {
    let ping: Ping

    var body: some View {
        Text(ping.text)
            .font(.syne(.bold, size: 17, relativeTo: .headline))
            .foregroundStyle(Color.pingTextPrimary)
            .lineSpacing(2)
            .lineLimit(2)
            .padding(.leading, 34)
    }
}

// MARK: - Meta Row

private struct MetaRow: View {
    let ping: Ping
    let urgency: PingUrgency
    let distanceText: String?

    var body: some View {
        HStack(spacing: 14) {
            UrgencyTimeLabel(ping: ping, urgency: urgency)

            if ping.imageUrl != nil {
                Image(systemName: "photo")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.pingTextSecondary.opacity(0.6))
            }

            HStack(spacing: 3) {
                Image(systemName: "flame")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.pingTextSecondary)
                Text("\(ping.boostCount)")
                    .font(.dmSans(.regular, size: 12, relativeTo: .caption))
                    .foregroundStyle(ping.boostCount > 0 ? Color.pingAccent : .pingTextSecondary)
            }

            HStack(spacing: 3) {
                Image(systemName: "person.2")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.pingTextSecondary)
                Text("\(ping.participantCount)")
                    .font(.dmSans(.regular, size: 12, relativeTo: .caption))
                    .foregroundStyle(Color.pingTextSecondary)
            }
        }
        .padding(.leading, 34)
    }
}

// MARK: - Urgency Time Label

private struct UrgencyTimeLabel: View {
    let ping: Ping
    let urgency: PingUrgency

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.system(size: 12))
            Text(ping.expiresAt.countdownDescription)
                .font(.dmSans(urgency == .normal ? .regular : .semiBold, size: 12, relativeTo: .caption))
        }
        .foregroundStyle(urgency.color)
    }
}
