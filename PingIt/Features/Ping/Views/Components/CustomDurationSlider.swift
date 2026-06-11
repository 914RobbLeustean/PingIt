import SwiftUI

struct CustomDurationSlider: View {
    @Binding var slotIndex: Int
    let slotCount: Int
    let timeLabel: String
    let durationLabel: String

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 2) {
                Text(timeLabel)
                    .font(.syne(.bold, size: 26, relativeTo: .title))
                    .foregroundStyle(Color.pingAccent)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.15), value: timeLabel)

                Text(durationLabel)
                    .font(.dmSans(.regular, size: 12, relativeTo: .caption))
                    .foregroundStyle(Color.pingTextSecondary)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.15), value: durationLabel)
            }
            .frame(maxWidth: .infinity)

            sliderTrack
        }
        .padding(16)
        .background(Color.pingSurfaceElevated)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.pingBorder, lineWidth: 1)
        )
    }

    private var sliderTrack: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width
            let maxIndex = max(slotCount - 1, 1)
            let fraction = CGFloat(slotIndex) / CGFloat(maxIndex)
            let thumbX = fraction * trackWidth

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.pingSurfaceElevated)
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.pingBorder, lineWidth: 1)
                    )
                    .frame(height: 6)

                Capsule()
                    .fill(Color.pingAccent)
                    .frame(width: max(6, thumbX), height: 6)

                Circle()
                    .fill(Color.pingAccent)
                    .frame(width: 24, height: 24)
                    .shadow(color: Color.pingAccent.opacity(0.4), radius: 8)
                    .offset(x: thumbX - 12)
            }
            .contentShape(.rect)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let rawFraction = value.location.x / trackWidth
                        let clampedFraction = min(max(rawFraction, 0), 1)
                        let newIndex = Int((clampedFraction * CGFloat(maxIndex)).rounded())
                        if newIndex != slotIndex {
                            slotIndex = newIndex
                        }
                    }
            )
            .sensoryFeedback(.selection, trigger: slotIndex)
        }
        .frame(height: 24)
    }
}
