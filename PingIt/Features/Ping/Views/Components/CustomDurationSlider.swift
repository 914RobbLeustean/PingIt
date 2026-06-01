import SwiftUI

struct CustomDurationSlider: View {
    @Binding var durationHours: Double
    let displayLabel: String
    let absoluteTimeLabel: String

    private let minHours: Double = 1.0
    private let maxHours: Double = 48.0
    private let snapInterval: Double = 0.5

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text(displayLabel)
                    .font(.syne(.bold, size: 28, relativeTo: .title))
                    .foregroundStyle(Color.pingAccent)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.15), value: displayLabel)

                Text("Expires at \(absoluteTimeLabel)")
                    .font(.dmSans(.regular, size: 12, relativeTo: .caption))
                    .foregroundStyle(Color.pingTextSecondary)
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 12) {
                Text("1h")
                    .font(.dmSans(.medium, size: 12, relativeTo: .caption))
                    .foregroundStyle(Color.pingTextSecondary)

                GeometryReader { geometry in
                    let trackWidth = geometry.size.width
                    let fraction = (durationHours - minHours) / (maxHours - minHours)
                    let thumbX = fraction * trackWidth

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.pingSurfaceElevated)
                            .frame(height: 6)

                        Capsule()
                            .fill(Color.pingAccent)
                            .frame(width: max(6, thumbX), height: 6)

                        Circle()
                            .fill(Color.pingAccent)
                            .frame(width: 22, height: 22)
                            .shadow(color: Color.pingAccent.opacity(0.4), radius: 8)
                            .offset(x: thumbX - 11)
                    }
                    .contentShape(.rect)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let rawFraction = value.location.x / trackWidth
                                let clampedFraction = min(max(rawFraction, 0), 1)
                                let rawHours = minHours + clampedFraction * (maxHours - minHours)
                                let snapped = (rawHours / snapInterval).rounded() * snapInterval
                                let newValue = min(max(snapped, minHours), maxHours)
                                if newValue != durationHours {
                                    durationHours = newValue
                                }
                            }
                    )
                    .sensoryFeedback(.selection, trigger: durationHours)
                }
                .frame(height: 22)

                Text("48h")
                    .font(.dmSans(.medium, size: 12, relativeTo: .caption))
                    .foregroundStyle(Color.pingTextSecondary)
            }
        }
        .padding(16)
        .background(Color.pingSurfaceElevated)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.pingBorder, lineWidth: 1)
        )
    }
}
