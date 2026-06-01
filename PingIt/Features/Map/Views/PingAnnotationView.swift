import SwiftUI

struct PingAnnotationView: View {
    let ping: Ping
    let isHot: Bool
    var onTap: () -> Void

    private var urgency: PingUrgency {
        .from(expiresAt: ping.expiresAt)
    }

    private var accentColor: Color {
        (isHot || urgency == .critical) ? .pingHot : .pingAccent
    }

    private var emoji: String {
        ping.category
            .flatMap(PingCategory.init(rawValue:))?
            .emoji ?? "📍"
    }

    private var displayBoosts: Int { ping.boostCount }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                PingPulseRings(color: accentColor, isCritical: urgency == .critical)
                    .allowsHitTesting(false)

                PingDot(emoji: emoji, accent: accentColor)
                    .modifier(CriticalShake(isActive: urgency == .critical))

                if displayBoosts > 0 {
                    PingBoostBadge(count: displayBoosts)
                        .offset(x: 18, y: -18)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: 52, height: 52)
            .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var parts: [String] = ["Ping: \(ping.text)", ping.expiresAt.countdownDescription]
        if isHot { parts.append("trending") }
        if urgency == .critical { parts.append("expiring soon") }
        if displayBoosts > 0 { parts.append("\(displayBoosts) boosts") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Dot

private struct PingDot: View {
    let emoji: String
    let accent: Color

    var body: some View {
        Circle()
            .fill(Color.pingSurface)
            .frame(width: 36, height: 36)
            .overlay(
                Circle().strokeBorder(accent, lineWidth: 2.5)
            )
            .overlay(
                Text(emoji)
                    .font(.system(size: 18))
            )
            .shadow(color: accent.opacity(0.45), radius: 8, y: 2)
    }
}

// MARK: - Pulse Rings

private struct PingPulseRings: View {
    let color: Color
    let isCritical: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var duration: Double { isCritical ? 1.8 : 2.8 }

    var body: some View {
        if reduceMotion {
            Circle()
                .strokeBorder(color.opacity(0.4), lineWidth: 1.5)
                .frame(width: 48, height: 48)
        } else {
            ZStack {
                PingPulseRing(color: color, duration: duration, delay: 0)
                PingPulseRing(color: color, duration: duration, delay: duration / 2)
            }
        }
    }
}

private struct PingPulseRing: View {
    let color: Color
    let duration: Double
    let delay: Double

    var body: some View {
        TimelineView(.animation) { context in
            let elapsed = context.date.timeIntervalSinceReferenceDate - delay
            let progress = elapsed > 0
                ? (elapsed.truncatingRemainder(dividingBy: duration)) / duration
                : 0
            let eased = 1 - pow(1 - progress, 2)
            let scale = 0.7 + (2.4 - 0.7) * eased

            Circle()
                .fill(color)
                .frame(width: 36, height: 36)
                .scaleEffect(scale)
                .opacity(elapsed > 0 ? 0.55 * (1 - progress) : 0)
        }
    }
}

// MARK: - Critical Shake

private struct CriticalShake: ViewModifier {
    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if isActive && !reduceMotion {
            content.modifier(CriticalShakeActive())
        } else {
            content
        }
    }
}

private struct CriticalShakeActive: ViewModifier {
    func body(content: Content) -> some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let offset = sin(t * 2 * .pi / 0.36) * 1.5
            content.offset(x: offset)
        }
    }
}

// MARK: - Boost Badge

private struct PingBoostBadge: View {
    let count: Int

    private var label: String {
        count > 99 ? "99+" : "\(count)"
    }

    var body: some View {
        Text(label)
            .font(.syne(.extraBold, size: 11))
            .foregroundStyle(.black)
            .padding(.horizontal, count > 9 ? 5 : 0)
            .frame(minWidth: 20, minHeight: 20)
            .background(Color.pingAccent, in: .capsule)
            .overlay(
                Capsule().strokeBorder(Color.pingBackground, lineWidth: 2)
            )
    }
}
