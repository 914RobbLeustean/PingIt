import SwiftUI

struct LoginView: View {
    @Environment(AuthService.self) private var authService
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("PingIt")
                    .font(.largeTitle)
                    .bold()

                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)

                SecureField("Password", text: $password)
                    .textContentType(isSignUp ? .newPassword : .password)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                Button(isSignUp ? "Create Account" : "Sign In") {
                    Task {
                        await authenticate()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(email.isEmpty || password.isEmpty || authService.isLoading)

                Button(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up") {
                    isSignUp.toggle()
                    errorMessage = nil
                }
                .font(.footnote)
            }
            .padding()
            .navigationTitle(isSignUp ? "Sign Up" : "Sign In")
        }
    }

    private func authenticate() async {
        errorMessage = nil
        do {
            if isSignUp {
                try await authService.signUp(email: email, password: password, username: email)
            } else {
                try await authService.signIn(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
