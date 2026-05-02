import SwiftUI

struct SuspendedAccountView: View {
    @Environment(AuthService.self) private var authService

    let expiresAt: Date?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.red)

            Text("Account Suspended")
                .font(.title)
                .bold()

            if let expiresAt {
                Text("Your account has been suspended until \(expiresAt.formatted(date: .abbreviated, time: .shortened)).")
                    .multilineTextAlignment(.center)
            } else {
                Text("Your account has been permanently suspended.")
                    .multilineTextAlignment(.center)
            }

            Text("If you believe this is an error, contact trvpapes@gmail.com to appeal.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button("Sign Out", role: .destructive, action: handleSignOut)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func handleSignOut() {
        try? authService.signOut()
    }
}
