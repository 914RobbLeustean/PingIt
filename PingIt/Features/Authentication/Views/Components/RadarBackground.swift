import SwiftUI

struct RadarBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                rings(in: proxy.size)
                dots(in: proxy.size)
            }
            .opacity(0.55)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    // MARK: Rings

    private static let ringStartRadius: CGFloat = 12
    private static let ringPeriod: TimeInterval = 3.0
    private static let ringDelays: [TimeInterval] = [0.0, 1.1, 2.2]

    @ViewBuilder
    private func rings(in size: CGSize) -> some View {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        if reduceMotion {
            ForEach(Self.ringDelays.indices, id: \.self) { _ in
                Self.ringShape(progress: 0.5, center: center)
            }
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { context in
                let now = context.date.timeIntervalSinceReferenceDate
                ForEach(Self.ringDelays.indices, id: \.self) { i in
                    let local = (now - Self.ringDelays[i]).truncatingRemainder(dividingBy: Self.ringPeriod)
                    let p = max(0, local) / Self.ringPeriod
                    Self.ringShape(progress: p, center: center)
                }
            }
        }
    }

    private static func ringShape(progress p: Double, center: CGPoint) -> some View {
        let eased = 1 - pow(1 - p, 3)  // ease-out cubic
        let scale = lerp(0.05, 7.0, eased)
        let opacity = lerp(0.9, 0.0, eased)
        return Circle()
            .stroke(Color.pingAccent, lineWidth: 1.2)
            .frame(width: ringStartRadius * 2, height: ringStartRadius * 2)
            .scaleEffect(scale)
            .opacity(opacity)
            .position(center)
    }

    // MARK: Dots

    private struct DotSpec {
        let x: CGFloat
        let y: CGFloat
        let phase: TimeInterval
    }

    private static let dotSpecs: [DotSpec] = [
        .init(x:  72, y: 210, phase: 0.4),
        .init(x: 295, y: 148, phase: 1.7),
        .init(x: 328, y: 272, phase: 0.1),
        .init(x:  55, y: 318, phase: 2.5),
        .init(x: 248, y: 362, phase: 1.0),
        .init(x: 140, y: 430, phase: 2.9),
        .init(x: 340, y: 195, phase: 0.7),
        .init(x: 180, y: 165, phase: 1.4),
    ]
    private static let referenceWidth: CGFloat = 390
    private static let referenceHeight: CGFloat = 650
    private static let dotPeriod: TimeInterval = 5.0

    @ViewBuilder
    private func dots(in size: CGSize) -> some View {
        let scaleX = size.width / Self.referenceWidth
        let scaleY = size.height / Self.referenceHeight
        if reduceMotion {
            ForEach(Self.dotSpecs.indices, id: \.self) { i in
                Self.dotShape(
                    opacity: 0.6,
                    at: Self.dotPosition(Self.dotSpecs[i], scaleX: scaleX, scaleY: scaleY)
                )
            }
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
                let now = context.date.timeIntervalSinceReferenceDate
                ForEach(Self.dotSpecs.indices, id: \.self) { i in
                    let spec = Self.dotSpecs[i]
                    let local = ((now + spec.phase).truncatingRemainder(dividingBy: Self.dotPeriod)) / Self.dotPeriod
                    let opacity = Self.dotOpacity(forCyclePosition: local)
                    Self.dotShape(
                        opacity: opacity,
                        at: Self.dotPosition(spec, scaleX: scaleX, scaleY: scaleY)
                    )
                }
            }
        }
    }

    private static func dotPosition(_ spec: DotSpec, scaleX: CGFloat, scaleY: CGFloat) -> CGPoint {
        CGPoint(x: spec.x * scaleX, y: spec.y * scaleY)
    }

    /// Maps a normalized cycle position (0...1) to an opacity:
    /// 0.00..0.15 → linear ramp 0 → 1
    /// 0.15..0.70 → 1
    /// 0.70..0.90 → linear ramp 1 → 0
    /// 0.90..1.00 → 0
    private static func dotOpacity(forCyclePosition t: Double) -> Double {
        switch t {
        case ..<0.15: return t / 0.15
        case ..<0.70: return 1.0
        case ..<0.90: return 1.0 - (t - 0.70) / 0.20
        default:      return 0.0
        }
    }

    @ViewBuilder
    private static func dotShape(opacity: Double, at point: CGPoint) -> some View {
        ZStack {
            Circle()
                .fill(Color.pingAccent.opacity(0.25))
                .frame(width: 12, height: 12)
            Circle()
                .fill(Color.pingAccent)
                .frame(width: 7, height: 7)
        }
        .opacity(opacity)
        .position(point)
    }
}

// MARK: - Helpers

private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
    a + (b - a) * t
}
