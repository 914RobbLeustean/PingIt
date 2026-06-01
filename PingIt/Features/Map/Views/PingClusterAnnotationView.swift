import SwiftUI

struct PingClusterAnnotationView: View {
    let count: Int
    let containsHotPing: Bool

    private var size: CGFloat {
        count < 10 ? 46 : count < 100 ? 52 : 58
    }

    private var labelFontSize: CGFloat {
        count < 10 ? 16 : 14
    }

    private var accent: Color {
        containsHotPing ? .pingHot : .pingAccent
    }

    private var displayCount: String {
        count > 999 ? "999+" : "\(count)"
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.pingSurface)
                .overlay(
                    Circle().strokeBorder(accent, lineWidth: 2.5)
                )
                .shadow(color: accent.opacity(0.35), radius: 8, y: 2)

            Text(displayCount)
                .font(.syne(.extraBold, size: labelFontSize))
                .foregroundStyle(accent)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(count) pings\(containsHotPing ? ", includes trending" : "")")
    }
}
