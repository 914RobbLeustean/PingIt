import SwiftUI

struct SettingsView: View {
    @Environment(AuthService.self) private var authService
    @Environment(UserService.self) private var userService
    @Environment(DataExportService.self) private var dataExportService

    @State private var path: [SettingsRoute] = []

    @State private var isPrivateProfile = UserDefaults.standard.bool(forKey: "pref_isPrivateProfile")
    @State private var notifyNearbyPings = UserDefaults.standard.object(forKey: "pref_notifyNearbyPings") as? Bool ?? true
    @State private var notifyHotPings = UserDefaults.standard.object(forKey: "pref_notifyHotPings") as? Bool ?? true
    @State private var notifyFollowActivity = UserDefaults.standard.object(forKey: "pref_notifyFollowActivity") as? Bool ?? true
    @State private var hasLoadedPreferences = false

    @State private var isExportingData = false
    @State private var exportedFileURL: URL?
    @State private var showShareSheet = false
    @State private var errorMessage: String?

    @State private var showSignOutDialog = false
    @State private var showDeleteFlow = false
    @State private var deleteViewModel = DeleteAccountViewModel()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.pingBackground.ignoresSafeArea()

                content

                PingItConfirmationDialog(isPresented: showSignOutDialog, onDismiss: dismissSignOutDialog) {
                    DialogTitleBlock(
                        title: "Sign out of PingIt?",
                        message: "You'll need to sign in again to see your pings."
                    )
                    DialogButtonRow {
                        Button("Cancel", action: dismissSignOutDialog)
                            .buttonStyle(DialogSecondaryButtonStyle())
                    } trailing: {
                        Button("Sign Out", action: confirmSignOut)
                            .buttonStyle(DialogDestructiveButtonStyle())
                    }
                }

                deleteAccountDialog
            }
            .navigationBarHidden(true)
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .blockedUsers:
                    BlockedUsersView()
                case .termsOfService:
                    TermsOfServiceView()
                case .privacyPolicy:
                    PrivacyPolicyView()
                }
            }
        }
        .task { await loadPreferences() }
        .onChange(of: notifyNearbyPings) { _, newValue in
            guard hasLoadedPreferences else { return }
            savePreference("notifyNearbyPings", value: newValue)
        }
        .onChange(of: notifyHotPings) { _, newValue in
            guard hasLoadedPreferences else { return }
            savePreference("notifyHotPings", value: newValue)
        }
        .onChange(of: notifyFollowActivity) { _, newValue in
            guard hasLoadedPreferences else { return }
            savePreference("notifyFollowActivity", value: newValue)
        }
        .onChange(of: isPrivateProfile) { _, newValue in
            guard hasLoadedPreferences else { return }
            savePreference("isPrivateProfile", value: newValue)
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedFileURL {
                ActivityViewRepresentable(items: [url])
            }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            Text("Settings")
                .font(.syne(.extraBold, size: 30, relativeTo: .largeTitle))
                .tracking(-0.5)
                .foregroundStyle(Color.pingTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 20)

            ScrollView {
                VStack(spacing: 20) {
                    accountSection
                    notificationsSection
                    privacySection
                    legalSection
                    deleteAccountSection

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.dmSans(.medium, size: 13, relativeTo: .footnote))
                            .foregroundStyle(Color.pingHot)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 90)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var accountSection: some View {
        SettingsSection("Account") {
            SettingsRow("Sign Out", labelColor: Color.pingHot, action: { showSignOutDialog = true }) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.pingHot)
            }
        }
    }

    private var notificationsSection: some View {
        SettingsSection("Notifications") {
            SettingsRow("Nearby Pings") {
                PingItToggle(isOn: $notifyNearbyPings, accessibilityLabel: "Nearby Pings")
            }
            SettingsRowDivider()
            SettingsRow("Hot Pings") {
                PingItToggle(isOn: $notifyHotPings, accessibilityLabel: "Hot Pings")
            }
            SettingsRowDivider()
            SettingsRow("Follow Activity") {
                PingItToggle(isOn: $notifyFollowActivity, accessibilityLabel: "Follow Activity")
            }
        }
    }

    private var privacySection: some View {
        SettingsSection("Privacy & Safety") {
            SettingsRow("Private Profile") {
                PingItToggle(isOn: $isPrivateProfile, accessibilityLabel: "Private Profile")
            }
            SettingsRowDivider()
            SettingsRow("Blocked Users", action: { path.append(.blockedUsers) })
            SettingsRowDivider()
            SettingsRow(
                "Export My Data",
                labelColor: Color.pingAccent,
                action: handleExportData
            ) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(isExportingData ? Color.pingAccent.opacity(0.4) : Color.pingAccent)
            }
        }
    }

    private var legalSection: some View {
        SettingsSection("Legal") {
            SettingsRow("Terms of Service", action: { path.append(.termsOfService) })
            SettingsRowDivider()
            SettingsRow("Privacy Policy", action: { path.append(.privacyPolicy) })
        }
    }

    private var deleteAccountSection: some View {
        SettingsSection(isDestructive: true) {
            SettingsRow("Delete Account", labelColor: Color.pingHot, action: openDeleteFlow) {
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var deleteAccountDialog: some View {
        switch deleteViewModel.step {
        case .confirmIntent:
            PingItConfirmationDialog(isPresented: showDeleteFlow, onDismiss: dismissDeleteFlow) {
                DialogTitleBlock(
                    title: "Delete account?",
                    message: "Press and hold the button below to continue. This is permanent — all your pings will disappear."
                )
                VStack(spacing: 10) {
                    HoldToConfirmButton("Delete Account") {
                        deleteViewModel.advanceToReauthenticate()
                    }
                    Button("Keep it", action: dismissDeleteFlow)
                        .buttonStyle(DialogSecondaryButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        case .farewell:
            PingItConfirmationDialog(isPresented: showDeleteFlow, onDismiss: {}) {
                AccountFarewellCard()
            }
        case .reauthenticate:
            PingItConfirmationDialog(isPresented: showDeleteFlow, onDismiss: dismissDeleteFlow) {
                DialogTitleBlock(
                    title: "Confirm your password",
                    message: "Re-enter your password to permanently delete this account."
                )
                VStack(spacing: 10) {
                    AuthPasswordField(
                        placeholder: "Password",
                        text: Bindable(deleteViewModel).password,
                        isVisible: Bindable(deleteViewModel).isPasswordVisible,
                        submitLabel: .done
                    )

                    if let error = deleteViewModel.errorMessage {
                        AuthFieldHint(message: error, tone: .error)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                DialogButtonRow {
                    Button("Cancel", action: dismissDeleteFlow)
                        .buttonStyle(DialogSecondaryButtonStyle())
                } trailing: {
                    Button(action: handleConfirmDelete) {
                        if deleteViewModel.isDeleting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Confirm Delete")
                        }
                    }
                    .buttonStyle(DialogDestructiveButtonStyle(
                        isEnabled: deleteViewModel.canConfirmDelete,
                        isLoading: deleteViewModel.isDeleting
                    ))
                    .disabled(!deleteViewModel.canConfirmDelete)
                }
            }
        }
    }

    // MARK: - Actions

    private func dismissSignOutDialog() {
        showSignOutDialog = false
    }

    private func confirmSignOut() {
        showSignOutDialog = false
        do {
            try authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func openDeleteFlow() {
        deleteViewModel.configure(authService: authService)
        deleteViewModel.reset()
        showDeleteFlow = true
    }

    private func dismissDeleteFlow() {
        showDeleteFlow = false
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            deleteViewModel.reset()
        }
    }

    private func handleConfirmDelete() {
        Task {
            let succeeded = await deleteViewModel.confirmDelete()
            guard succeeded else { return }
            // Linger on the farewell card before the auth listener
            // tears the session down and navigates back to Welcome.
            try? await Task.sleep(for: .seconds(4))
            deleteViewModel.finalizeSignOut()
        }
    }

    private func handleExportData() {
        guard !isExportingData else { return }
        isExportingData = true
        errorMessage = nil
        Task {
            do {
                let jsonData = try await dataExportService.exportUserData()
                let fileURL = URL.temporaryDirectory.appending(path: "PingIt-data-export.json")
                try jsonData.write(to: fileURL)
                exportedFileURL = fileURL
                showShareSheet = true
            } catch {
                errorMessage = "Data export failed. Please try again."
            }
            isExportingData = false
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
            notifyFollowActivity = user.notifyFollowActivity ?? true
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
        UserDefaults.standard.set(user.notifyFollowActivity ?? true, forKey: "pref_notifyFollowActivity")
    }
}
