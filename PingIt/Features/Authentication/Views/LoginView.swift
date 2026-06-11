import SwiftUI

struct LoginView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = LoginViewModel()
    @FocusState private var focusedField: Field?

    enum Field: Hashable { case email, password }

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            Color.pingBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                AuthScreenHeader(title: "Sign In") { dismiss() }

                ScrollView {
                    VStack(spacing: 12) {
                        AuthInputField(
                            placeholder: "Email",
                            text: $viewModel.email,
                            icon: "envelope",
                            keyboardType: .emailAddress,
                            contentType: .emailAddress,
                            submitLabel: .next
                        )
                        .focused($focusedField, equals: .email)
                        .onSubmit { focusedField = .password }

                        AuthPasswordField(
                            placeholder: "Password",
                            text: $viewModel.password,
                            isVisible: $viewModel.isPasswordVisible,
                            contentType: .password,
                            submitLabel: .go
                        )
                        .focused($focusedField, equals: .password)
                        .onSubmit { submit(viewModel: viewModel) }

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.dmSans(.regular, size: 13, relativeTo: .footnote))
                                .foregroundStyle(Color.pingHot)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            submit(viewModel: viewModel)
                        } label: {
                            Text(viewModel.isLoading ? "Signing in…" : "Sign In")
                        }
                        .buttonStyle(AuthCTAButtonStyle(
                            isEnabled: viewModel.canSubmit,
                            isLoading: viewModel.isLoading
                        ))
                        .disabled(!viewModel.canSubmit)
                        .padding(.top, 8)

                        NavigationLink(value: AuthRoute.forgotPassword) {
                            Text("Forgot Password?")
                                .font(.dmSans(.regular, size: 13, relativeTo: .footnote))
                                .foregroundStyle(Color.pingTextSecondary)
                        }
                        .padding(.top, 4)
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
            viewModel.configure(authService: authService)
        }
    }

    private func submit(viewModel: LoginViewModel) {
        guard viewModel.canSubmit else { return }
        focusedField = nil
        Task { await viewModel.authenticate() }
    }
}
