import Foundation

@Observable
@MainActor
final class DeleteAccountViewModel {
    enum Step {
        case confirmIntent
        case reauthenticate
        case farewell
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

    func confirmDelete() async -> Bool {
        guard let authService, !password.isEmpty else { return false }
        isDeleting = true
        errorMessage = nil

        do {
            try await authService.reauthenticate(password: password)
            try await authService.deleteAccount()
            isDeleting = false
            step = .farewell
            return true
        } catch {
            errorMessage = error.localizedDescription
            isDeleting = false
            return false
        }
    }
}
