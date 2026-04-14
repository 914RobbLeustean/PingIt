import Foundation

@Observable
@MainActor
final class ForgotPasswordViewModel {
    private var authService: (any AuthServicing)?
    private var isConfigured = false

    var email = ""
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var didSendReset = false

    var isEmailValid: Bool {
        !email.isEmpty && email.range(of: Constants.Email.validationPattern, options: .regularExpression) != nil
    }

    var emailValidationMessage: String? {
        guard !email.isEmpty else { return nil }
        return isEmailValid ? nil : "Enter a valid email address"
    }

    var canSubmit: Bool {
        isEmailValid && !isLoading
    }

    func configure(authService: any AuthServicing) {
        guard !isConfigured else { return }
        self.authService = authService
        isConfigured = true
    }

    func sendReset() async {
        guard let authService, canSubmit else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await authService.sendPasswordReset(email: email)
            didSendReset = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
