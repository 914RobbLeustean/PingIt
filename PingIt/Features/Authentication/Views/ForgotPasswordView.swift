import SwiftUI

struct ForgotPasswordView: View {
    @Environment(AuthService.self) private var authService
    @State private var viewModel = ForgotPasswordViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "lock.rotation")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Reset Password")
                        .font(.title2)
                        .bold()
                    Text("Enter your email and we'll send you a link to reset your password.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)

                if viewModel.didSendReset {
                    successView
                } else {
                    resetForm(viewModel: viewModel)
                }
            }
            .padding()
        }
        .navigationTitle("Forgot Password")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.configure(authService: authService)
        }
    }

    private var successView: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.badge.checkmark")
                .font(.largeTitle)
                .foregroundStyle(.green)
            Text("Check your email for a reset link.")
                .font(.body)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func resetForm(viewModel: ForgotPasswordViewModel) -> some View {
        @Bindable var viewModel = viewModel

        return VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
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

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button("Send Reset Link") {
                Task { await viewModel.sendReset() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .disabled(!viewModel.canSubmit)
        }
    }

    private func emailValidationState(viewModel: ForgotPasswordViewModel) -> ValidationState? {
        guard !viewModel.email.isEmpty else { return nil }
        return viewModel.isEmailValid ? .valid : .invalid
    }
}
