import SwiftUI

struct LoginView: View {
    @Environment(AuthService.self) private var authService
    @State private var viewModel = LoginViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(spacing: 24) {
                emailSection(viewModel: viewModel)
                passwordSection(viewModel: viewModel)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button("Sign In") {
                    Task { await viewModel.authenticate() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(!viewModel.canSubmit)

                NavigationLink("Forgot Password?", value: AuthRoute.forgotPassword)
                    .font(.footnote)
            }
            .padding()
        }
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.configure(authService: authService)
        }
    }

    // MARK: - Sections

    private func emailSection(viewModel: LoginViewModel) -> some View {
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

    private func passwordSection(viewModel: LoginViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return AuthSecureField(
            title: "Password",
            text: $viewModel.password,
            isVisible: $viewModel.isPasswordVisible,
            textContentType: .password
        )
    }

    // MARK: - Validation states

    private func emailValidationState(viewModel: LoginViewModel) -> ValidationState? {
        guard !viewModel.email.isEmpty else { return nil }
        return viewModel.isEmailValid ? .valid : .invalid
    }
}
