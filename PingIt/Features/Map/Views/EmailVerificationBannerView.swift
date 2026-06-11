import SwiftUI

struct EmailVerificationBannerView: View {
    let onResend: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        MapAlertChip(
            severity: .warning,
            icon: "envelope.badge",
            title: "Verify your email",
            message: "Confirm to create pings and unlock chat.",
            primaryAction: .init(label: "Resend", handler: onResend),
            onDismiss: onDismiss
        )
    }
}
