import Foundation

@Observable
final class LoginViewModel {
    private var authService: (any AuthServicing)?
    private var isConfigured = false

    var email = ""
    var password = ""
    var username = ""
    var isSignUp = false
    private(set) var errorMessage: String?

    var isLoading: Bool { authService?.isLoading ?? false }

    var canSubmit: Bool {
        let hasCredentials = !email.isEmpty && !password.isEmpty
        if isSignUp {
            return hasCredentials && isUsernameValid
        }
        return hasCredentials
    }

    var isUsernameValid: Bool {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return trimmed.count >= Constants.Username.minLength
            && trimmed.count <= Constants.Username.maxLength
            && trimmed.range(of: Constants.Username.allowedCharacterPattern, options: .regularExpression) != nil
    }

    var usernameValidationMessage: String? {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.count < Constants.Username.minLength {
            return PingItError.usernameTooShort.localizedDescription
        }
        if trimmed.count > Constants.Username.maxLength {
            return PingItError.usernameTooLong.localizedDescription
        }
        if trimmed.range(of: Constants.Username.allowedCharacterPattern, options: .regularExpression) == nil {
            return PingItError.usernameInvalidCharacters.localizedDescription
        }
        return nil
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
            if isSignUp {
                try await authService.signUp(
                    email: email,
                    password: password,
                    username: username.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            } else {
                try await authService.signIn(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleMode() {
        isSignUp.toggle()
        errorMessage = nil
    }
}
