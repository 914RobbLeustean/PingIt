import SwiftUI

struct MessageInputBar: View {
    @Binding var text: String
    let isSending: Bool
    let canSend: Bool
    let onSend: () -> Void
    let onShareLocation: () -> Void

    private var trimmedIsEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.pingBorder)
                .frame(height: 1)

            HStack(spacing: 10) {
                Button(action: onShareLocation) {
                    Image(systemName: "location")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.pingTextSecondary)
                        .frame(width: 44, height: 44)
                        .background(Color.pingSurface, in: .circle)
                        .overlay(
                            Circle().strokeBorder(Color.pingBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Share location")

                TextField("", text: $text, axis: .vertical)
                    .placeholder(when: text.isEmpty) {
                        Text("say something…")
                            .foregroundStyle(Color.pingTextSecondary)
                    }
                    .font(.dmSans(.regular, size: 14, relativeTo: .body))
                    .foregroundStyle(Color.pingTextPrimary)
                    .tint(Color.pingAccent)
                    .lineLimit(1...4)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.pingSurface)
                    .clipShape(.capsule)
                    .overlay(
                        Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .onSubmit(onSend)

                Button(action: onSend) {
                    Group {
                        if isSending {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.black)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundStyle(trimmedIsEmpty ? Color.pingTextSecondary : .black)
                    .frame(width: 44, height: 44)
                    .background(
                        trimmedIsEmpty ? Color.pingSurface : Color.pingAccent,
                        in: .circle
                    )
                    .shadow(
                        color: Color.pingAccent.opacity(trimmedIsEmpty ? 0 : 0.3),
                        radius: 10
                    )
                    .animation(.easeInOut(duration: 0.2), value: trimmedIsEmpty)
                }
                .buttonStyle(.plain)
                .disabled(trimmedIsEmpty || !canSend)
                .accessibilityLabel("Send message")
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 8)
        }
        .background(Color.pingBackground)
    }
}

// MARK: - Placeholder helper

private extension View {
    @ViewBuilder
    func placeholder<Placeholder: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Placeholder
    ) -> some View {
        ZStack(alignment: alignment) {
            if shouldShow { placeholder() }
            self
        }
    }
}
