import SwiftUI

/// Floating glass alert chip used for map-level notifications (email
/// verification, location denied, errors, empty state). Designed to sit below
/// the floating map title.
struct MapAlertChip: View {
    enum Severity {
        case info
        case warning
        case error

        var accent: Color {
            switch self {
            case .info:    .pingAccent
            case .warning: .pingAccent
            case .error:   .pingHot
            }
        }
    }

    let severity: Severity
    let icon: String
    let title: String
    let message: String?
    let primaryAction: Action?
    let onDismiss: (() -> Void)?

    struct Action {
        let label: String
        let handler: () -> Void
    }

    init(
        severity: Severity,
        icon: String,
        title: String,
        message: String? = nil,
        primaryAction: Action? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.severity = severity
        self.icon = icon
        self.title = title
        self.message = message
        self.primaryAction = primaryAction
        self.onDismiss = onDismiss
    }

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 12) {
            MapAlertAccentStripe(color: severity.accent)

            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(severity.accent)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: message == nil ? 0 : 2) {
                Text(title)
                    .font(.dmSans(.semiBold, size: 13, relativeTo: .footnote))
                    .foregroundStyle(Color.pingTextPrimary)
                    .lineLimit(1)
                if let message {
                    Text(message)
                        .font(.dmSans(.regular, size: 12, relativeTo: .caption))
                        .foregroundStyle(Color.pingTextSecondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 8)

            if let action = primaryAction {
                Button(action: action.handler) {
                    Text(action.label)
                        .font(.dmSans(.semiBold, size: 12, relativeTo: .caption))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .frame(height: 28)
                        .background(severity.accent, in: .capsule)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(action.label)
            }

            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.pingTextSecondary)
                        .frame(width: 24, height: 24)
                        .background(Color.pingSurfaceElevated, in: .circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss")
            }
        }
        .padding(.leading, 6)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .background(alignment: .leading) {
            chipBackground
        }
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.pingBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.45), radius: 18, y: 8)
        .shadow(color: severity.accent.opacity(0.18), radius: 14)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -16)
        .task {
            withAnimation(reduceMotion ? .linear(duration: 0.001) :
                .spring(response: 0.45, dampingFraction: 0.78)) {
                appeared = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(primaryAction.map { "Double tap to \($0.label.lowercased())" } ?? "")
    }

    private var chipBackground: some View {
        ZStack {
            Color.pingSurface.opacity(0.85)
            LinearGradient(
                colors: [severity.accent.opacity(0.18), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .blendMode(.plusLighter)
        }
        .background(.ultraThinMaterial)
    }
}

private struct MapAlertAccentStripe: View {
    let color: Color
    @State private var glow = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Capsule()
            .fill(color)
            .frame(width: 3, height: 28)
            .shadow(color: color.opacity(glow ? 0.9 : 0.4), radius: glow ? 6 : 3)
            .task {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    glow = true
                }
            }
    }
}
