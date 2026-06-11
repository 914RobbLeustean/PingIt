import Foundation

@Observable
@MainActor
final class RegisterViewModel {
    private var authService: (any AuthServicing)?
    private var userService: (any UserServicing)?
    private var isConfigured = false
    private var usernameCheckTask: Task<Void, Never>?

    // MARK: - Input state

    var email = ""
    var username = ""
    var password = ""
    var confirmPassword = ""
    var hasAcceptedTerms = false
    var isPasswordVisible = false
    var isConfirmPasswordVisible = false

    // MARK: - Derived state

    private(set) var usernameAvailability: UsernameAvailability = .unchecked
    private(set) var passwordValidation: PasswordValidator.Result = PasswordValidator.validate("")
    private(set) var errorMessage: String?
    private(set) var isLoading = false

    // MARK: - UsernameAvailability

    enum UsernameAvailability {
        case unchecked
        case checking
        case available
        case taken
        case error
    }

    // MARK: - Computed validation

    var isEmailValid: Bool {
        !email.isEmpty && email.range(of: Constants.Email.validationPattern, options: .regularExpression) != nil
    }

    var emailValidationMessage: String? {
        guard !email.isEmpty else { return nil }
        return isEmailValid ? nil : "Please enter a valid email address."
    }

    var isUsernameFormatValid: Bool {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return trimmed.count >= Constants.Username.minLength
            && trimmed.count <= Constants.Username.maxLength
            && trimmed.range(of: Constants.Username.allowedCharacterPattern, options: .regularExpression) != nil
    }

    var usernameFormatMessage: String? {
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

    var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }

    var passwordsMatchMessage: String? {
        guard !confirmPassword.isEmpty else { return nil }
        return passwordsMatch ? nil : PingItError.passwordsDoNotMatch.localizedDescription
    }

    var canSubmit: Bool {
        guard !isLoading else { return false }
        return isEmailValid
            && isUsernameFormatValid
            && usernameAvailability == .available
            && passwordValidation.allRulesMet
            && passwordsMatch
            && hasAcceptedTerms
    }

    // MARK: - Configuration

    func configure(authService: any AuthServicing, userService: any UserServicing) {
        guard !isConfigured else { return }
        self.authService = authService
        self.userService = userService
        isConfigured = true
    }

    // MARK: - Actions

    func passwordDidChange() {
        passwordValidation = PasswordValidator.validate(password)
    }

    func usernameDidChange() {
        usernameCheckTask?.cancel()
        usernameAvailability = .unchecked

        guard isUsernameFormatValid else { return }

        usernameAvailability = .checking
        usernameCheckTask = Task {
            try? await Task.sleep(for: .milliseconds(Constants.Username.uniquenessCheckDebounceMilliseconds))
            guard !Task.isCancelled else { return }
            await checkUsernameAvailability()
        }
    }

    func register() async {
        guard let authService, canSubmit else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await authService.signUp(
                email: email,
                password: password,
                username: username.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Testing support

    /// Sets username availability directly. Only for use in unit tests.
    func setUsernameAvailabilityForTesting(_ availability: UsernameAvailability) {
        usernameAvailability = availability
    }

    // MARK: - Private

    private func checkUsernameAvailability() async {
        guard let userService else { return }
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let taken = try await userService.isUsernameTaken(trimmed)
            usernameAvailability = taken ? .taken : .available
        } catch {
            usernameAvailability = .error
        }
    }
}
