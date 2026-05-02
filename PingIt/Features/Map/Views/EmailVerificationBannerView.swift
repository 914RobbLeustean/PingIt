import SwiftUI

struct EmailVerificationBannerView: View {
    let onResend: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "envelope.badge")
                .foregroundStyle(.orange)

            Text("Verify your email to create pings")
                .font(.subheadline)

            Spacer()

            Button("Resend", action: onResend)
                .font(.subheadline)
                .bold()

            Button("Dismiss", systemImage: "xmark", action: onDismiss)
                .labelStyle(.iconOnly)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 12))
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
    }
}
