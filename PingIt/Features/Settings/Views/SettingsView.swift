import SwiftUI

struct SettingsView: View {
    @Environment(AuthService.self) private var authService
    @Environment(UserService.self) private var userService
    @State private var showSignOutConfirmation = false
    @State private var errorMessage: String?
    @State private var isPrivateProfile = UserDefaults.standard.bool(forKey: "pref_isPrivateProfile")
    @State private var notifyNearbyPings = UserDefaults.standard.object(forKey: "pref_notifyNearbyPings") as? Bool ?? true
    @State private var notifyHotPings = UserDefaults.standard.object(forKey: "pref_notifyHotPings") as? Bool ?? true
    @State private var hasLoadedPreferences = false
    @State private var showDeleteConfirmation = false
    @State private var showPasswordPrompt = false
    @State private var deletePassword = ""
    @State private var isDeletingAccount = false

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
                    guard hasLoadedPreferences else { return }
                    savePreference("notifyNearbyPings", value: newValue)
                }
                .onChange(of: notifyHotPings) { _, newValue in
                    guard hasLoadedPreferences else { return }
                    savePreference("notifyHotPings", value: newValue)
                }

                Section("Privacy & Safety") {
                    Toggle("Private Profile", isOn: $isPrivateProfile)
                    NavigationLink("Blocked Users", destination: BlockedUsersView())
                }
                .onChange(of: isPrivateProfile) { _, newValue in
                    guard hasLoadedPreferences else { return }
                    savePreference("isPrivateProfile", value: newValue)
                }

                Section("Legal") {
                    NavigationLink("Terms of Service", destination: TermsOfServiceView())
                    NavigationLink("Privacy Policy", destination: PrivacyPolicyView())
                }

                Section {
                    Button("Delete Account", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                    .disabled(isDeletingAccount)
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
            .alert("Delete your account?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    showPasswordPrompt = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your account and all your data. This cannot be undone.")
            }
            .alert("Confirm your password", isPresented: $showPasswordPrompt) {
                SecureField("Password", text: $deletePassword)
                Button("Confirm Delete", role: .destructive) {
                    handleDeleteAccount()
                }
                Button("Cancel", role: .cancel) {
                    deletePassword = ""
                }
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

    private func handleDeleteAccount() {
        let password = deletePassword
        deletePassword = ""
        isDeletingAccount = true

        Task {
            do {
                try await authService.reauthenticate(password: password)
                try await authService.deleteAccount()
            } catch {
                errorMessage = error.localizedDescription
                isDeletingAccount = false
            }
        }
    }

    private func loadPreferences() async {
        guard let userId = authService.currentUser?.uid else {
            hasLoadedPreferences = true
            return
        }
        if let user = try? await userService.fetchUser(id: userId) {
            isPrivateProfile = user.isPrivateProfile
            notifyNearbyPings = user.notifyNearbyPings
            notifyHotPings = user.notifyHotPings
            cachePreferences(user)
        }
        hasLoadedPreferences = true
    }

    private func savePreference(_ key: String, value: Bool) {
        UserDefaults.standard.set(value, forKey: "pref_\(key)")
        guard let userId = authService.currentUser?.uid else { return }
        Task {
            try? await userService.updateUser(id: userId, data: [key: value])
        }
    }

    private func cachePreferences(_ user: User) {
        UserDefaults.standard.set(user.isPrivateProfile, forKey: "pref_isPrivateProfile")
        UserDefaults.standard.set(user.notifyNearbyPings, forKey: "pref_notifyNearbyPings")
        UserDefaults.standard.set(user.notifyHotPings, forKey: "pref_notifyHotPings")
    }
}
