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

    @State private var phase = 0

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 36, height: 36)
            .scaleEffect(phase == 0 ? 0.7 : 2.4)
            .opacity(phase == 0 ? 0.55 : 0)
            .task {
                try? await Task.sleep(for: .seconds(delay))
                withAnimation(
                    .easeOut(duration: duration).repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

// MARK: - Critical Shake

private struct CriticalShake: ViewModifier {
    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .task(id: isActive) {
                guard isActive, !reduceMotion else {
                    offset = 0
                    return
                }
                withAnimation(
                    .easeInOut(duration: 0.18).repeatForever(autoreverses: true)
                ) {
                    offset = 1.5
                }
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
