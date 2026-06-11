import SwiftUI

struct ForgotPasswordView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ForgotPasswordViewModel()
    @FocusState private var emailFocused: Bool

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            Color.pingBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                AuthScreenHeader(title: "Reset Password") { dismiss() }

                ScrollView {
                    if viewModel.didSendReset {
                        successState(viewModel: viewModel)
                    } else {
                        formState(viewModel: viewModel)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            viewModel.configure(authService: authService)
        }
    }

    private func formState(viewModel: ForgotPasswordViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return VStack(alignment: .leading, spacing: 16) {
            Text("Enter your email and we'll send you a link to reset your password.")
                .font(.dmSans(.regular, size: 14, relativeTo: .body))
                .foregroundStyle(Color.pingTextSecondary)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 6) {
                AuthInputField(
                    placeholder: "Email",
                    text: $viewModel.email,
                    icon: "envelope",
                    keyboardType: .emailAddress,
                    contentType: .emailAddress,
                    submitLabel: .send
                )
                .focused($emailFocused)
                .onSubmit { submit(viewModel: viewModel) }

                if let message = viewModel.emailValidationMessage {
                    AuthFieldHint(message: message, tone: .error)
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.dmSans(.regular, size: 13, relativeTo: .footnote))
                    .foregroundStyle(Color.pingHot)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                submit(viewModel: viewModel)
            } label: {
                Text(viewModel.isLoading ? "Sending…" : "Send Reset Link")
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

    private func successState(viewModel: ForgotPasswordViewModel) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.pingAccent.opacity(0.12))
                    .frame(width: 88, height: 88)
                Circle()
                    .fill(Color.pingAccent.opacity(0.18))
                    .frame(width: 56, height: 56)
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Color.pingAccent)
            }
            .padding(.top, 16)

            Text("Check your inbox")
                .font(.syne(.extraBold, size: 22, relativeTo: .title2))
                .foregroundStyle(Color.pingTextPrimary)

            Text("If an account exists for \(viewModel.email), a reset link is on its way.")
                .font(.dmSans(.regular, size: 14, relativeTo: .body))
                .foregroundStyle(Color.pingTextSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 8)

            Button("Back to Sign In") {
                dismiss()
            }
            .buttonStyle(AuthCTAButtonStyle(isEnabled: true))
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 24)
    }

    private func submit(viewModel: ForgotPasswordViewModel) {
        guard viewModel.canSubmit else { return }
        emailFocused = false
        Task { await viewModel.sendReset() }
    }
}
