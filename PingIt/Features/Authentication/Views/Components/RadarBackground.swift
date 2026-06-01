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

    private static let ringPeriod: TimeInterval = 5.0
    private static let ringDelays: [TimeInterval] = [0.0, 1.666, 3.333]
    private static let ringLineWidth: CGFloat = 2.0

    /// Origin in canvas-local coordinates. (0, 0) = top-left of the radar layer.
    private static let origin = CGPoint.zero

    @ViewBuilder
    private func rings(in size: CGSize) -> some View {
        let maxRadius = hypot(size.width, size.height)
        if reduceMotion {
            ringsCanvas(progresses: Self.ringDelays.map { _ in 0.5 }, maxRadius: maxRadius)
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { context in
                let now = context.date.timeIntervalSinceReferenceDate
                let progresses = Self.ringDelays.map { delay in
                    let local = (now - delay).truncatingRemainder(dividingBy: Self.ringPeriod)
                    return max(0, local) / Self.ringPeriod
                }
                ringsCanvas(progresses: progresses, maxRadius: maxRadius)
            }
        }
    }

    /// Draws all rings into a single Canvas so they share a coordinate space and
    /// can't be displaced by any SwiftUI layout quirks. Every ring is centered
    /// at `(0, 0)` in the Canvas's local coordinates, which is the top-left of
    /// the radar layer.
    private func ringsCanvas(progresses: [Double], maxRadius: CGFloat) -> some View {
        Canvas { context, _ in
            for p in progresses {
                let radius = maxRadius * p
                let opacity = lerp(0.9, 0.0, p)
                let rect = CGRect(
                    x: Self.origin.x - radius,
                    y: Self.origin.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )
                let path = Path(ellipseIn: rect)
                context.stroke(
                    path,
                    with: .color(Color.pingAccent.opacity(opacity)),
                    lineWidth: Self.ringLineWidth
                )
            }
        }
        // Critically: the Canvas itself must fill the entire radar layer so its
        // local (0,0) coincides with the radar layer's top-left.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Dots

    private struct DotSpec {
        let x: CGFloat
        let y: CGFloat
        let phase: TimeInterval
    }

    /// 16 dots spread across a 390×844 reference viewport (iPhone-shape).
    /// Positions hand-picked to avoid clustering and to keep the top-left
    /// region — where rings spawn — sparser so the rings read clearly.
    private static let dotSpecs: [DotSpec] = [
        .init(x: 320, y:  90, phase: 0.4),
        .init(x: 245, y: 145, phase: 2.1),
        .init(x: 350, y: 215, phase: 1.2),
        .init(x: 175, y: 200, phase: 3.4),
        .init(x:  90, y: 285, phase: 0.7),
        .init(x: 280, y: 305, phase: 2.8),
        .init(x: 360, y: 380, phase: 1.6),
        .init(x: 200, y: 415, phase: 4.1),
        .init(x:  60, y: 460, phase: 0.2),
        .init(x: 305, y: 480, phase: 3.6),
        .init(x: 140, y: 540, phase: 1.9),
        .init(x: 250, y: 595, phase: 4.4),
        .init(x:  85, y: 645, phase: 2.5),
        .init(x: 345, y: 670, phase: 0.9),
        .init(x: 200, y: 730, phase: 3.1),
        .init(x: 290, y: 790, phase: 1.4),
    ]
    private static let referenceWidth: CGFloat = 390
    private static let referenceHeight: CGFloat = 844
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
