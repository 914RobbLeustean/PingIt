import SwiftUI
import UIKit

struct HoldToConfirmButton: View {
    let title: String
    let holdDuration: Double
    let onComplete: () -> Void

    init(_ title: String, holdDuration: Double = 7.5, onComplete: @escaping () -> Void) {
        self.title = title
        self.holdDuration = holdDuration
        self.onComplete = onComplete
    }

    @State private var progress: Double = 0
    @State private var isHolding = false
    @State private var didComplete = false
    @State private var holdStartedAt: Date?
    @State private var shake: CGFloat = 0
    @State private var milestonesFired: Set<Int> = []

    private let cornerRadius: CGFloat = 24
    private let height: CGFloat = 48

    var body: some View {
        layered
            .frame(height: height)
            .scaleEffect(isHolding && !didComplete ? 0.98 : 1)
            .offset(x: shake)
            .shadow(
                color: Color.pingHot.opacity(0.3 + 0.4 * progress),
                radius: 10 + 14 * progress,
                x: 0, y: 0
            )
            .animation(.easeOut(duration: 0.15), value: isHolding)
            .contentShape(.rect)
            .gesture(holdGesture)
            .accessibilityLabel("\(title). Press and hold to confirm.")
            .accessibilityAddTraits(.isButton)
    }

    private var layered: some View {
        ZStack {
            track
            fill
            label
        }
    }

    private var track: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.pingSurface)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.pingHot.opacity(0.4 + 0.4 * progress), lineWidth: 1)
            )
    }

    private var fill: some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(fillGradient)
                .frame(width: max(0, geo.size.width * progress))
                .shadow(color: Color.pingHot.opacity(0.5), radius: 12, x: 0, y: 0)
                .animation(.linear(duration: 0.05), value: progress)
        }
        .clipShape(.rect(cornerRadius: cornerRadius))
        .allowsHitTesting(false)
    }

    private var fillGradient: LinearGradient {
        LinearGradient(
            colors: [Color.pingHot, Color.pingHot.opacity(0.85)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var label: some View {
        Text(currentLabel)
            .font(.syne(.bold, size: 15))
            .tracking(-0.2)
            .foregroundStyle(textColor)
            .id(currentLabel)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .bottom)),
                removal: .opacity.combined(with: .move(edge: .top))
            ))
            .animation(.easeInOut(duration: 0.25), value: currentLabel)
    }

    private var holdGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isHolding && !didComplete {
                    beginHold()
                }
            }
            .onEnded { _ in
                if !didComplete {
                    cancelHold()
                }
            }
    }

    private var currentLabel: String {
        if didComplete                  { return "Goodbye." }
        if !isHolding && progress < 0.01 { return title }
        if progress < 0.10 { return "Keep holding..." }
        if progress < 0.25 { return "You sure about this?" }
        if progress < 0.42 { return "All your pings will be gone." }
        if progress < 0.60 { return "Your chats will vanish too." }
        if progress < 0.75 { return "Last chance to let go..." }
        if progress < 0.88 { return "We'll really miss you." }
        if progress < 0.97 { return "Almost there..." }
        return "Goodbye."
    }

    private var textColor: Color {
        progress > 0.45 ? Color.white : Color.pingHot
    }

    private func beginHold() {
        isHolding = true
        holdStartedAt = Date()
        milestonesFired = []
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        tick()
    }

    private func cancelHold() {
        isHolding = false
        holdStartedAt = nil
        withAnimation(.easeOut(duration: 0.25)) {
            progress = 0
        }
        shake = 0
        milestonesFired = []
    }

    private func complete() {
        guard !didComplete else { return }
        didComplete = true
        isHolding = false

        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            onComplete()
            try? await Task.sleep(for: .milliseconds(450))
            progress = 0
            didComplete = false
            shake = 0
            milestonesFired = []
        }
    }

    private func tick() {
        guard isHolding, !didComplete, let start = holdStartedAt else { return }

        let elapsed = Date().timeIntervalSince(start)
        let raw = min(elapsed / holdDuration, 1.0)
        // Ease-out cubic: starts fast, slows toward the end
        let eased = 1 - pow(1 - raw, 3)
        progress = eased

        // Milestone haptics: a light tap every 10% of progress
        let milestone = Int(eased * 10)
        if milestone > 0 && !milestonesFired.contains(milestone) {
            milestonesFired.insert(milestone)
            let style: UIImpactFeedbackGenerator.FeedbackStyle = milestone >= 8 ? .medium : .light
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        }

        if eased > 0.55 {
            // Shake ramps in over a longer window now (55% → 100%)
            let intensity = (eased - 0.55) / 0.45
            let magnitude = CGFloat.random(in: -1...1) * (1.0 + intensity * 6.0)
            withAnimation(.linear(duration: 0.03)) {
                shake = magnitude
            }
        } else {
            shake = 0
        }

        if raw >= 1 {
            shake = 0
            complete()
            return
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(16))
            tick()
        }
    }
}
