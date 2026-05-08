import SwiftUI

struct RegisterView: View {
    @Environment(AuthService.self) private var authService
    @Environment(UserService.self) private var userService
    @State private var viewModel = RegisterViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(spacing: 24) {
                emailSection(viewModel: viewModel)
                usernameSection(viewModel: viewModel)
                passwordSection(viewModel: viewModel)
                confirmPasswordSection(viewModel: viewModel)
                tosSection(viewModel: viewModel)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button("Create Account") {
                    Task { await viewModel.register() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(!viewModel.canSubmit)
            }
            .padding()
        }
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.configure(authService: authService, userService: userService)
        }
    }

    // MARK: - Sections

    private func emailSection(viewModel: RegisterViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return VStack(alignment: .leading, spacing: 6) {
            AuthTextField(
                title: "Email",
                text: $viewModel.email,
                icon: "envelope",
                validationState: emailValidationState(viewModel: viewModel),
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )
            if let message = viewModel.emailValidationMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 4)
            }
        }
    }

    private func usernameSection(viewModel: RegisterViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return VStack(alignment: .leading, spacing: 6) {
            AuthTextField(
                title: "Username",
                text: $viewModel.username,
                icon: "person",
                validationState: usernameValidationState(viewModel: viewModel),
                textContentType: .username
            )
            .onChange(of: viewModel.username) {
                viewModel.usernameDidChange()
            }
            usernameHint(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private func usernameHint(viewModel: RegisterViewModel) -> some View {
        if let message = viewModel.usernameFormatMessage {
            Text(message)
                .font(.caption)
                .foregroundStyle(.red)
                .padding(.horizontal, 4)
        } else if viewModel.usernameAvailability == .taken {
            Text("This username is already taken.")
                .font(.caption)
                .foregroundStyle(.red)
                .padding(.horizontal, 4)
        } else if viewModel.usernameAvailability == .error {
            Text("Could not check availability. Please try again.")
                .font(.caption)
                .foregroundStyle(.orange)
                .padding(.horizontal, 4)
        }
    }

    private func passwordSection(viewModel: RegisterViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return VStack(alignment: .leading, spacing: 8) {
            AuthSecureField(
                title: "Password",
                text: $viewModel.password,
                isVisible: $viewModel.isPasswordVisible,
                textContentType: .newPassword
            )
            .onChange(of: viewModel.password) {
                viewModel.passwordDidChange()
            }
            if !viewModel.password.isEmpty {
                PasswordStrengthView(result: viewModel.passwordValidation)
            }
        }
    }

    private func confirmPasswordSection(viewModel: RegisterViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return VStack(alignment: .leading, spacing: 6) {
            AuthSecureField(
                title: "Confirm Password",
                text: $viewModel.confirmPassword,
                isVisible: $viewModel.isConfirmPasswordVisible,
                textContentType: .newPassword
            )
            if let message = viewModel.passwordsMatchMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 4)
            }
        }
    }

    private func tosSection(viewModel: RegisterViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return HStack(alignment: .top, spacing: 8) {
            Button(viewModel.hasAcceptedTerms ? "Accepted" : "Accept terms", systemImage: viewModel.hasAcceptedTerms ? "checkmark.square.fill" : "square") {
                viewModel.hasAcceptedTerms.toggle()
            }
            .labelStyle(.iconOnly)
            .foregroundStyle(viewModel.hasAcceptedTerms ? Color.accentColor : .secondary)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("I agree to the")
                        .font(.subheadline)
                    NavigationLink("Terms of Service", value: AuthRoute.termsOfService)
                        .font(.subheadline)
                        .underline()
                }
                HStack(spacing: 4) {
                    Text("and the")
                        .font(.subheadline)
                    NavigationLink("Privacy Policy", value: AuthRoute.privacyPolicy)
                        .font(.subheadline)
                        .underline()
                }
            }
        }
    }

    // MARK: - Validation states

    private func emailValidationState(viewModel: RegisterViewModel) -> ValidationState? {
        guard !viewModel.email.isEmpty else { return nil }
        return viewModel.isEmailValid ? .valid : .invalid
    }

    private func usernameValidationState(viewModel: RegisterViewModel) -> ValidationState? {
        guard !viewModel.username.isEmpty else { return nil }
        if !viewModel.isUsernameFormatValid { return .invalid }
        switch viewModel.usernameAvailability {
        case .checking: return .checking
        case .available: return .valid
        case .taken, .error: return .invalid
        case .unchecked: return nil
        }
    }
}
