import SwiftUI

struct RegisterView: View {
    @Environment(AuthService.self) private var authService
    @Environment(UserService.self) private var userService
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = RegisterViewModel()
    @FocusState private var focusedField: Field?

    enum Field: Hashable { case email, username, password, confirmPassword }

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            Color.pingBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                AuthScreenHeader(title: "Create Account") { dismiss() }

                ScrollView {
                    VStack(spacing: 12) {
                        emailField(viewModel: viewModel)
                        usernameField(viewModel: viewModel)
                        passwordField(viewModel: viewModel)
                        confirmPasswordField(viewModel: viewModel)
                        termsRow(viewModel: viewModel)

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.dmSans(.regular, size: 13, relativeTo: .footnote))
                                .foregroundStyle(Color.pingHot)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            submit(viewModel: viewModel)
                        } label: {
                            Text(viewModel.isLoading ? "Creating…" : "Create Account")
                        }
                        .buttonStyle(AuthCTAButtonStyle(
                            isEnabled: viewModel.canSubmit,
                            isLoading: viewModel.isLoading
                        ))
                        .disabled(!viewModel.canSubmit)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            viewModel.configure(authService: authService, userService: userService)
        }
    }

    private func submit(viewModel: RegisterViewModel) {
        guard viewModel.canSubmit else { return }
        focusedField = nil
        Task { await viewModel.register() }
    }

    // MARK: - Fields

    private func emailField(viewModel: RegisterViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return VStack(alignment: .leading, spacing: 6) {
            AuthInputField(
                placeholder: "Email",
                text: $viewModel.email,
                icon: "envelope",
                keyboardType: .emailAddress,
                contentType: .emailAddress,
                submitLabel: .next
            )
            .focused($focusedField, equals: .email)
            .onSubmit { focusedField = .username }

            if let message = viewModel.emailValidationMessage {
                AuthFieldHint(message: message, tone: .error)
            }
        }
    }

    private func usernameField(viewModel: RegisterViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return VStack(alignment: .leading, spacing: 6) {
            AuthInputField(
                placeholder: "Username",
                text: $viewModel.username,
                icon: "person",
                contentType: .username,
                submitLabel: .next
            )
            .focused($focusedField, equals: .username)
            .onChange(of: viewModel.username) {
                viewModel.usernameDidChange()
            }
            .onSubmit { focusedField = .password }

            usernameHint(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private func usernameHint(viewModel: RegisterViewModel) -> some View {
        if let message = viewModel.usernameFormatMessage {
            AuthFieldHint(message: message, tone: .error)
        } else {
            switch viewModel.usernameAvailability {
            case .taken:
                AuthFieldHint(message: "This username is already taken.", tone: .error)
            case .error:
                AuthFieldHint(message: "Could not check availability. Try again.", tone: .soft)
            case .checking:
                AuthFieldHint(message: "Checking availability…", tone: .soft)
            case .available:
                AuthFieldHint(message: "Username available.", tone: .success)
            case .unchecked:
                EmptyView()
            }
        }
    }

    private func passwordField(viewModel: RegisterViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return VStack(alignment: .leading, spacing: 8) {
            AuthPasswordField(
                placeholder: "Password",
                text: $viewModel.password,
                isVisible: $viewModel.isPasswordVisible,
                contentType: .newPassword,
                submitLabel: .next
            )
            .focused($focusedField, equals: .password)
            .onChange(of: viewModel.password) {
                viewModel.passwordDidChange()
            }
            .onSubmit { focusedField = .confirmPassword }

            if !viewModel.password.isEmpty {
                PasswordStrengthView(result: viewModel.passwordValidation)
            }
        }
    }

    private func confirmPasswordField(viewModel: RegisterViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return VStack(alignment: .leading, spacing: 6) {
            AuthPasswordField(
                placeholder: "Confirm Password",
                text: $viewModel.confirmPassword,
                isVisible: $viewModel.isConfirmPasswordVisible,
                contentType: .newPassword,
                submitLabel: .go
            )
            .focused($focusedField, equals: .confirmPassword)
            .onSubmit { submit(viewModel: viewModel) }

            if let message = viewModel.passwordsMatchMessage {
                AuthFieldHint(message: message, tone: .error)
            }
        }
    }

    private func termsRow(viewModel: RegisterViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return HStack(alignment: .top, spacing: 10) {
            AuthCheckbox(isChecked: $viewModel.hasAcceptedTerms)
                .padding(.top, 1)

            HStack(spacing: 0) {
                Text("I agree to the ")
                    .foregroundStyle(Color.pingTextSecondary)
                NavigationLink(value: AuthRoute.termsOfService) {
                    Text("Terms")
                        .foregroundStyle(Color.pingAccent)
                }
                Text(" and ")
                    .foregroundStyle(Color.pingTextSecondary)
                NavigationLink(value: AuthRoute.privacyPolicy) {
                    Text("Privacy Policy")
                        .foregroundStyle(Color.pingAccent)
                }
            }
            .font(.dmSans(.regular, size: 13, relativeTo: .footnote))

            Spacer(minLength: 0)
        }
        .padding(.leading, 2)
        .padding(.top, 4)
    }
}
