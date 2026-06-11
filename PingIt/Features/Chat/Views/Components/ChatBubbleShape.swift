import SwiftUI

/// Per-corner rounded shape used for chat message bubbles (gives one corner a
/// small "tail" while the others stay generously rounded).
struct ChatBubbleShape: Shape {
    let topLeading: CGFloat
    let topTrailing: CGFloat
    let bottomLeading: CGFloat
    let bottomTrailing: CGFloat

    func path(in rect: CGRect) -> Path {
        // A bubble can briefly receive a zero-sized rect during layout;
        // returning an empty path avoids drawing invalid arcs.
        guard rect.width > 0, rect.height > 0 else { return Path() }
        let cap = max(0, min(rect.width, rect.height) / 2)
        let tl = max(0, min(topLeading, cap))
        let tr = max(0, min(topTrailing, cap))
        let bl = max(0, min(bottomLeading, cap))
        let br = max(0, min(bottomTrailing, cap))

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        path.addArc(
            center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr),
            radius: tr,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        path.addArc(
            center: CGPoint(x: rect.maxX - br, y: rect.maxY - br),
            radius: br,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        path.addArc(
            center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl),
            radius: bl,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        path.addArc(
            center: CGPoint(x: rect.minX + tl, y: rect.minY + tl),
            radius: tl,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}
