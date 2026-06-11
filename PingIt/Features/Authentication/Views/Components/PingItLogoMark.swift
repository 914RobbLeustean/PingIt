import SwiftUI

/// 18×18pt amber core with two halo layers and a slow breathing pulse.
/// Total footprint at peak: 28×28pt.
struct PingItLogoMark: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let pulsePeriod: TimeInterval = 2.0

    var body: some View {
        ZStack {
            outerGlow
            midRing
            core
        }
        .frame(width: 28, height: 28)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var outerGlow: some View {
        if reduceMotion {
            glow(scale: 1.2, opacity: 0.45)
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
                let now = context.date.timeIntervalSinceReferenceDate
                let t = (now.truncatingRemainder(dividingBy: Self.pulsePeriod)) / Self.pulsePeriod
                let pulse = (1 - cos(2 * .pi * t)) / 2
                let scale = 1.0 + pulse * 0.4
                let opacity = 0.6 - pulse * 0.3
                glow(scale: scale, opacity: opacity)
            }
        }
    }

    private func glow(scale: Double, opacity: Double) -> some View {
        Circle()
            .fill(Color.pingAccent.opacity(0.20))
            .frame(width: 28, height: 28)
            .scaleEffect(scale)
            .opacity(opacity)
    }

    private var midRing: some View {
        Circle()
            .fill(Color.pingAccent.opacity(0.35))
            .frame(width: 22, height: 22)
    }

    private var core: some View {
        Circle()
            .fill(Color.pingAccent)
            .frame(width: 18, height: 18)
    }
}
