import SwiftUI

struct OnboardingPageView: View {
    let emoji: String
    let accentSymbol: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            OnboardingHero(emoji: emoji, accentSymbol: accentSymbol)
                .padding(.bottom, 44)

            Text(title)
                .font(.syne(.extraBold, size: 28, relativeTo: .largeTitle))
                .foregroundStyle(Color.pingTextPrimary)
                .tracking(-0.5)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 14)

            Text(subtitle)
                .font(.dmSans(.regular, size: 15, relativeTo: .body))
                .foregroundStyle(Color.pingTextSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 36)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

// MARK: - Hero

private struct OnboardingHero: View {
    let emoji: String
    let accentSymbol: String

    var body: some View {
        ZStack {
            OnboardingHeroPulse()
                .frame(width: 240, height: 240)

            Circle()
                .fill(Color.pingSurface)
                .frame(width: 156, height: 156)
                .overlay(
                    Circle().strokeBorder(Color.pingBorder, lineWidth: 1)
                )
                .shadow(color: Color.pingAccent.opacity(0.25), radius: 30)

            Text(emoji)
                .font(.system(size: 76))
                .accessibilityHidden(true)

            Image(systemName: accentSymbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 44, height: 44)
                .background(Color.pingAccent, in: .circle)
                .shadow(color: Color.pingAccent.opacity(0.5), radius: 12)
                .offset(x: 58, y: -58)
                .accessibilityHidden(true)
        }
    }
}

private struct OnboardingHeroPulse: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            Circle()
                .strokeBorder(Color.pingAccent.opacity(0.15), lineWidth: 1)
        } else {
            TimelineView(.animation) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                ZStack {
                    pulseRing(at: t, offset: 0)
                    pulseRing(at: t, offset: 1.5)
                }
            }
        }
    }

    private func pulseRing(at time: TimeInterval, offset: TimeInterval) -> some View {
        let duration: Double = 3.0
        let elapsed = (time + offset).truncatingRemainder(dividingBy: duration)
        let progress = elapsed / duration
        let eased = 1 - pow(1 - progress, 2)
        let scale = 0.6 + 0.55 * eased
        return Circle()
            .strokeBorder(Color.pingAccent, lineWidth: 1.5)
            .scaleEffect(scale)
            .opacity(0.35 * (1 - progress))
    }
}
