import SwiftUI

struct PingFeedCardView: View {
    let ping: Ping
    let creator: User?
    let distanceText: String?
    let urgency: PingUrgency
    let isHot: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var urgencyPulse = false

    var body: some View {
        HStack(spacing: 0) {
            UrgencyEdgeBar(urgency: urgency, reduceMotion: reduceMotion)

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
        .background(cardBackground)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(cardBorderColor, lineWidth: isHot ? 1.5 : 1)
        )
        .shadow(color: cardShadowColor, radius: isHot ? 14 : 10)
        .scaleEffect(urgencyScale)
        .animation(urgencyAnimation, value: urgencyPulse)
        .onAppear {
            if urgency == .critical, !reduceMotion {
                urgencyPulse = true
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var cardBackground: some ShapeStyle {
        if urgency == .critical {
            return AnyShapeStyle(
                Color.pingSurface
                    .shadow(.inner(color: .pingHot.opacity(urgencyPulse ? 0.12 : 0.04), radius: urgencyPulse ? 12 : 4))
            )
        }
        return AnyShapeStyle(Color.pingSurface)
    }

    private var cardBorderColor: Color {
        if isHot { return .pingHot.opacity(0.35) }
        if urgency == .critical { return .pingHot.opacity(urgencyPulse ? 0.25 : 0.1) }
        return .pingBorder
    }

    private var cardShadowColor: Color {
        if isHot { return .pingHot.opacity(0.18) }
        return .clear
    }

    private var urgencyScale: CGFloat {
        guard urgency == .critical, !reduceMotion else { return 1.0 }
        return urgencyPulse ? 0.985 : 1.0
    }

    private var urgencyAnimation: Animation? {
        guard urgency == .critical, !reduceMotion else { return nil }
        return .easeInOut(duration: 2.8).repeatForever(autoreverses: true)
    }
}

// MARK: - Urgency Edge Bar

private struct UrgencyEdgeBar: View {
    let urgency: PingUrgency
    let reduceMotion: Bool

    @State private var shimmer = false

    var body: some View {
        if urgency != .normal {
            Rectangle()
                .fill(urgency.color)
                .frame(width: 4)
                .overlay(shimmerOverlay)
                .onAppear {
                    if urgency == .urgent, !reduceMotion {
                        shimmer = true
                    }
                }
        }
    }

    @ViewBuilder
    private var shimmerOverlay: some View {
        if urgency == .urgent, !reduceMotion {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.3), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .offset(y: shimmer ? 60 : -60)
                .animation(
                    .easeInOut(duration: 2.2)
                    .repeatForever(autoreverses: false)
                    .delay(1.0),
                    value: shimmer
                )
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
