import Foundation

@Observable
@MainActor
final class DeleteAccountViewModel {
    enum Step {
        case confirmIntent
        case reauthenticate
    }

    var step: Step = .confirmIntent
    var password: String = ""
    var isPasswordVisible: Bool = false
    var isDeleting: Bool = false
    var errorMessage: String?

    private var authService: AuthService?

    func configure(authService: AuthService) {
        self.authService = authService
    }

    func reset() {
        step = .confirmIntent
        password = ""
        isPasswordVisible = false
        isDeleting = false
        errorMessage = nil
    }

    func advanceToReauthenticate() {
        step = .reauthenticate
        errorMessage = nil
    }

    var canConfirmDelete: Bool {
        !password.isEmpty && !isDeleting
    }

    func confirmDelete() async {
        guard let authService, !password.isEmpty else { return }
        isDeleting = true
        errorMessage = nil
        defer { isDeleting = false }

        do {
            try await authService.reauthenticate(password: password)
            try await authService.deleteAccount()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
