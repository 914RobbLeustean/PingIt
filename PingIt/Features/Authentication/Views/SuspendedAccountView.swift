import SwiftUI

struct SuspendedAccountView: View {
    @Environment(AuthService.self) private var authService

    let expiresAt: Date?

    var body: some View {
        ZStack {
            Color.pingBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                SuspendedHero()
                    .padding(.bottom, 28)

                Text("Account Suspended")
                    .font(.syne(.extraBold, size: 26, relativeTo: .largeTitle))
                    .foregroundStyle(Color.pingTextPrimary)
                    .tracking(-0.4)
                    .padding(.bottom, 12)

                Text(primaryMessage)
                    .font(.dmSans(.regular, size: 15, relativeTo: .body))
                    .foregroundStyle(Color.pingTextPrimary)
                    .lineSpacing(3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 14)

                Text("If you believe this is an error, contact trvpapes@gmail.com to appeal.")
                    .font(.dmSans(.regular, size: 13, relativeTo: .footnote))
                    .foregroundStyle(Color.pingTextSecondary)
                    .lineSpacing(3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                SuspendedSignOutButton(action: handleSignOut)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var primaryMessage: String {
        if let expiresAt {
            return "Your account has been suspended until \(expiresAt.formatted(date: .abbreviated, time: .shortened))."
        }
        return "Your account has been permanently suspended."
    }

    private func handleSignOut() {
        try? authService.signOut()
    }
}

// MARK: - Hero

private struct SuspendedHero: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.pingHot.opacity(0.12))
                .frame(width: 156, height: 156)

            Circle()
                .strokeBorder(Color.pingHot.opacity(0.3), lineWidth: 1)
                .frame(width: 124, height: 124)

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(Color.pingHot)
                .shadow(color: Color.pingHot.opacity(0.4), radius: 20)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Sign Out Button

private struct SuspendedSignOutButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Sign Out")
                .font(.syne(.extraBold, size: 14))
                .tracking(-0.3)
                .foregroundStyle(Color.pingTextPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.pingSurface, in: .capsule)
                .overlay(
                    Capsule().strokeBorder(Color.pingBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Sign out")
    }
}
