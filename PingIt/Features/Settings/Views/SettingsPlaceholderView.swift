import SwiftUI

struct SettingsView: View {
    @Environment(AuthService.self) private var authService
    @State private var showSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    Button("Sign Out", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive, action: handleSignOutTap)
                        .alert("Sign out of PingIt?", isPresented: $showSignOutConfirmation) {
                            Button("Sign Out", role: .destructive, action: handleConfirmSignOut)
                            Button("Cancel", role: .cancel) {}
                        }
                }
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - Actions

    private func handleSignOutTap() {
        showSignOutConfirmation = true
    }

    private func handleConfirmSignOut() {
        try? authService.signOut()
    }
}
