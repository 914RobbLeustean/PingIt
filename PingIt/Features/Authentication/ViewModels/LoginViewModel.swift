import Foundation

@Observable
@MainActor
final class LoginViewModel {
    private var authService: (any AuthServicing)?
    private var isConfigured = false

    var email = ""
    var password = ""
    var isPasswordVisible = false
    private(set) var errorMessage: String?

    var isLoading: Bool { authService?.isLoading ?? false }

    var canSubmit: Bool {
        guard !isLoading else { return false }
        return isEmailValid && !password.isEmpty
    }

    var isEmailValid: Bool {
        !email.isEmpty && email.range(of: Constants.Email.validationPattern, options: .regularExpression) != nil
    }

    var emailValidationMessage: String? {
        guard !email.isEmpty else { return nil }
        return isEmailValid ? nil : "Please enter a valid email address."
    }

    func configure(authService: any AuthServicing) {
        guard !isConfigured else { return }
        self.authService = authService
        isConfigured = true
    }

    func authenticate() async {
        guard let authService else { return }
        errorMessage = nil
        do {
            try await authService.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
