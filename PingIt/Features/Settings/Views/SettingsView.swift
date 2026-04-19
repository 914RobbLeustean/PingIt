import SwiftUI

struct SettingsView: View {
    @Environment(AuthService.self) private var authService
    @Environment(UserService.self) private var userService
    @State private var showSignOutConfirmation = false
    @State private var errorMessage: String?
    @State private var isPrivateProfile = false
    @State private var notifyNearbyPings = true
    @State private var notifyHotPings = true

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

                Section("Notifications") {
                    Toggle("Nearby Pings", isOn: $notifyNearbyPings)
                    Toggle("Hot Pings", isOn: $notifyHotPings)
                }
                .onChange(of: notifyNearbyPings) { _, newValue in
                    savePreference("notifyNearbyPings", value: newValue)
                }
                .onChange(of: notifyHotPings) { _, newValue in
                    savePreference("notifyHotPings", value: newValue)
                }

                Section("Privacy & Safety") {
                    Toggle("Private Profile", isOn: $isPrivateProfile)
                    NavigationLink("Blocked Users", destination: BlockedUsersView())
                }
                .onChange(of: isPrivateProfile) { _, newValue in
                    savePreference("isPrivateProfile", value: newValue)
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .task {
                await loadPreferences()
            }
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

    private func loadPreferences() async {
        guard let userId = authService.currentUser?.uid else { return }
        if let user = try? await userService.fetchUser(id: userId) {
            isPrivateProfile = user.isPrivateProfile
            notifyNearbyPings = user.notifyNearbyPings
            notifyHotPings = user.notifyHotPings
        }
    }

    private func savePreference(_ key: String, value: Bool) {
        guard let userId = authService.currentUser?.uid else { return }
        Task {
            try? await userService.updateUser(id: userId, data: [key: value])
        }
    }
}
