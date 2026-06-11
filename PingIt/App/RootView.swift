import SwiftUI
import FirebaseAuth

struct RootView: View {
    @Environment(AuthService.self) private var authService
    @Environment(UserService.self) private var userService

    @State private var currentUserProfile: User?
    @State private var isCheckingSuspension = true

    private var isSuspended: Bool {
        guard let profile = currentUserProfile,
              let status = profile.suspensionStatus else { return false }
        guard status == "suspended" || status == "banned" else { return false }
        if status == "banned" { return true }
        if let expiresAt = profile.suspensionExpiresAt {
            return expiresAt > Date.now
        }
        return true
    }

    var body: some View {
        Group {
            if let currentUser = authService.currentUser {
                if isCheckingSuspension {
                    ProgressView()
                } else if isSuspended {
                    SuspendedAccountView(expiresAt: currentUserProfile?.suspensionExpiresAt)
                } else if currentUserProfile?.hasCompletedOnboarding != true {
                    OnboardingView(
                        userId: currentUser.uid,
                        onComplete: {
                            currentUserProfile?.hasCompletedOnboarding = true
                        }
                    )
                } else {
                    MainTabView()
                }
            } else {
                AuthenticationCoordinatorView()
            }
        }
        .animation(.default, value: authService.currentUser?.uid)
        .task(id: authService.currentUser?.uid) {
            await checkSuspension()
        }
    }

    private func checkSuspension() async {
        guard let firebaseUser = authService.currentUser else {
            currentUserProfile = nil
            isCheckingSuspension = false
            return
        }
        isCheckingSuspension = true
        do {
            currentUserProfile = try await userService.fetchUser(id: firebaseUser.uid)
        } catch {
            // Auth user with no Firestore doc — backfill so onboarding and
            // every other feature has a valid doc to read/update.
            let email = Auth.auth().currentUser?.email ?? ""
            if let backfilled = try? await userService.ensureUserProfileExists(
                uid: firebaseUser.uid,
                email: email
            ) {
                currentUserProfile = backfilled
            } else {
                currentUserProfile = nil
            }
        }
        isCheckingSuspension = false
    }
}
