import SwiftUI

struct LoginView: View {
    @Environment(AuthService.self) private var authService
    @State private var viewModel = LoginViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            VStack(spacing: 20) {
                Text("PingIt")
                    .font(.largeTitle)
                    .bold()

                TextField("Email", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)

                if viewModel.isSignUp {
                    TextField("Username", text: $viewModel.username)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    if let validationMessage = viewModel.usernameValidationMessage {
                        Text(validationMessage)
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }

                SecureField("Password", text: $viewModel.password)
                    .textContentType(viewModel.isSignUp ? .newPassword : .password)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                Button(
                    viewModel.isSignUp ? "Create Account" : "Sign In",
                    action: handleAuthenticate
                )
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.canSubmit == false || viewModel.isLoading)

                Button(
                    viewModel.isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up",
                    action: handleToggleMode
                )
                .font(.footnote)
            }
            .padding()
            .navigationTitle(viewModel.isSignUp ? "Sign Up" : "Sign In")
            .task {
                viewModel.configure(authService: authService)
            }
        }
    }

    // MARK: - Actions

    private func handleAuthenticate() {
        Task {
            await viewModel.authenticate()
        }
    }

    private func handleToggleMode() {
        viewModel.toggleMode()
    }
}
