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
                    VStack(spacing: 16) {
                        Image(systemName: "envelope.badge")
                            .font(.largeTitle)
                            .foregroundStyle(.green)
                        Text("If an account exists for **\(self.viewModel.email)**, a reset link has been sent.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            AuthTextField(
                                title: "Email",
                                text: $viewModel.email,
                                icon: "envelope",
                                validationState: viewModel.email.isEmpty ? nil : viewModel.isEmailValid ? .valid : .invalid,
                                keyboardType: .emailAddress,
                                textContentType: .emailAddress
                            )
                            if let message = self.viewModel.emailValidationMessage {
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
            }
            .padding()
        }
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("Forgot Password")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.configure(authService: authService)
        }
    }
}
