import SwiftUI

struct AuthenticationCoordinatorView: View {
    @State private var path: [AuthRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView(path: $path)
                .navigationDestination(for: AuthRoute.self) { route in
                    switch route {
                    case .login:
                        LoginView()
                    case .register:
                        RegisterView()
                    case .forgotPassword:
                        ForgotPasswordView()
                    case .termsOfService:
                        TermsOfServiceView()
                    case .privacyPolicy:
                        PrivacyPolicyView()
                    }
                }
        }
    }
}
