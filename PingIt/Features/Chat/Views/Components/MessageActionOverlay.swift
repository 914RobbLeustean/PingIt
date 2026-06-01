import SwiftUI

/// Floating overlay shown when a chat bubble is long-pressed.
///
/// Renders a translucent backdrop, a horizontally-scrollable reaction pill
/// above the lifted bubble, and a stacked action sheet below for
/// Report / Block (omitted for the current user's own messages).
struct MessageActionOverlay: View {
    let isCurrentUser: Bool
    let onReaction: (String) -> Void
    let onReport: () -> Void
    let onBlock: () -> Void
    let onDismiss: () -> Void

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .background(.ultraThinMaterial)
                .onTapGesture(perform: dismiss)

            VStack(spacing: 14) {
                ReactionPickerPill(
                    isVisible: appeared,
                    onReaction: { emoji in
                        onReaction(emoji)
                        dismiss()
                    }
                )

                if !isCurrentUser {
                    MessageActionSheet(
                        onReport: {
                            onReport()
                            dismiss()
                        },
                        onBlock: {
                            onBlock()
                            dismiss()
                        }
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 14)
                }
            }
            .padding(.horizontal, 24)
        }
        .accessibilityAddTraits(.isModal)
        .task {
            withAnimation(reduceMotion
                ? .linear(duration: 0.001)
                : .spring(response: 0.42, dampingFraction: 0.72)) {
                appeared = true
            }
        }
    }

    private func dismiss() {
        withAnimation(reduceMotion
            ? .linear(duration: 0.001)
            : .easeOut(duration: 0.18)) {
            appeared = false
        }
        Task {
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 160))
            onDismiss()
        }
    }
}

// MARK: - Reaction Pill

private struct ReactionPickerPill: View {
    let isVisible: Bool
    let onReaction: (String) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Constants.Reaction.available.indices, id: \.self) { index in
                let reaction = Constants.Reaction.available[index]
                ReactionEmojiButton(
                    emoji: reaction.emoji,
                    delay: Double(index) * 0.025,
                    appeared: isVisible,
                    onTap: { onReaction(reaction.emoji) }
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.pingSurface)
                .overlay(
                    Capsule().strokeBorder(Color.pingBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 24, y: 10)
                .shadow(color: Color.pingAccent.opacity(0.2), radius: 14)
        )
        .scaleEffect(isVisible ? 1 : 0.6, anchor: .center)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 12)
    }
}

private struct ReactionEmojiButton: View {
    let emoji: String
    let delay: Double
    let appeared: Bool
    let onTap: () -> Void

    @State private var bumped = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            triggerBump()
            onTap()
        } label: {
            Text(emoji)
                .font(.system(size: 26))
                .frame(width: 38, height: 38)
                .scaleEffect(scale)
                .opacity(appeared ? 1 : 0)
                .animation(
                    appeared
                        ? .spring(response: 0.4, dampingFraction: 0.55).delay(delay)
                        : .easeOut(duration: 0.12),
                    value: appeared
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("React with \(emoji)")
    }

    private var scale: CGFloat {
        if !appeared { return 0.4 }
        return bumped ? 1.35 : 1.0
    }

    private func triggerBump() {
        guard !reduceMotion else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.45)) {
            bumped = true
        }
    }
}

// MARK: - Action Sheet (Report / Block)

private struct MessageActionSheet: View {
    let onReport: () -> Void
    let onBlock: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ActionRow(
                icon: "exclamationmark.bubble",
                label: "Report Message",
                tint: Color.pingTextPrimary,
                action: onReport
            )

            Rectangle()
                .fill(Color.pingBorder)
                .frame(height: 1)

            ActionRow(
                icon: "hand.raised",
                label: "Block User",
                tint: Color.pingHot,
                action: onBlock
            )
        }
        .background(Color.pingSurface, in: .rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.pingBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 20, y: 8)
    }
}

private struct ActionRow: View {
    let icon: String
    let label: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 22)
                Text(label)
                    .font(.dmSans(.semiBold, size: 15, relativeTo: .body))
                Spacer()
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 16)
            .frame(height: 48)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
