import SwiftUI

struct SettingsView: View {
    @Environment(AuthService.self) private var authService
    @State private var showSignOutConfirmation = false
    @State private var errorMessage: String?

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

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
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
        do {
            try authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
