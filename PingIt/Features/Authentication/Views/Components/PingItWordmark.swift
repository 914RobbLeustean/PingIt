import SwiftUI

/// Composes the animated logo dot with the "PINGIT" Syne wordmark.
/// Read by VoiceOver as "PingIt" (not letter-by-letter).
struct PingItWordmark: View {
    var body: some View {
        HStack(spacing: 12) {
            PingItLogoMark()
            Text("PINGIT")
                .font(.syne(.extraBold, size: 34))
                .tracking(-1)
                .foregroundStyle(Color.pingTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: true, vertical: false)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("PingIt")
        .accessibilityAddTraits(.isHeader)
    }
}
