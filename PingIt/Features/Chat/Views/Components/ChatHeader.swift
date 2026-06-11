import SwiftUI

struct ChatHeader: View {
    let ping: Ping?
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                AuthBackButton(action: onBack)

                ChatHeaderTitleBlock(ping: ping)

                Spacer(minLength: 8)

                if let ping {
                    ChatUrgencyPill(expiresAt: ping.expiresAt)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Rectangle()
                .fill(Color.pingBorder)
                .frame(height: 1)
        }
        .background(Color.pingBackground)
    }
}

// MARK: - Title Block (ping emoji + title + LIVE pulse)

private struct ChatHeaderTitleBlock: View {
    let ping: Ping?

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(titleText)
                .font(.syne(.extraBold, size: 16, relativeTo: .headline))
                .foregroundStyle(Color.pingTextPrimary)
                .tracking(-0.3)
                .lineLimit(1)

            ChatLivePulse()
        }
    }

    private var titleText: String {
        guard let ping else { return "Chat" }
        if let category = ping.category.flatMap(PingCategory.init(rawValue:)) {
            return "\(category.emoji)  \(ping.text)"
        }
        return ping.text
    }
}

// MARK: - LIVE pulse

private struct ChatLivePulse: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 5) {
            if reduceMotion {
                Circle()
                    .fill(Color.pingLive)
                    .frame(width: 6, height: 6)
            } else {
                TimelineView(.animation) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    let pulse = 0.5 * (1 + sin(t * .pi))
                    Circle()
                        .fill(Color.pingLive)
                        .frame(width: 6, height: 6)
                        .scaleEffect(0.75 + 0.25 * pulse)
                        .opacity(0.4 + 0.6 * pulse)
                }
                .frame(width: 6, height: 6)
            }

            Text("LIVE")
                .font(.dmSans(.semiBold, size: 11, relativeTo: .caption))
                .tracking(0.5)
                .foregroundStyle(Color.pingLive)
        }
        .accessibilityLabel("Live chat")
    }
}

// MARK: - Urgency Pill

struct ChatUrgencyPill: View {
    let expiresAt: Date

    private var urgency: PingUrgency {
        .from(expiresAt: expiresAt)
    }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "clock.fill")
                .font(.system(size: 11))
            Text(expiresAt.countdownDescription)
                .font(.dmSans(.semiBold, size: 12, relativeTo: .caption))
        }
        .foregroundStyle(urgency.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(urgency.color.opacity(0.1), in: .capsule)
        .overlay(
            Capsule().strokeBorder(urgency.color.opacity(0.25), lineWidth: 1)
        )
        .accessibilityLabel("Expires \(expiresAt.countdownDescription)")
    }
}
