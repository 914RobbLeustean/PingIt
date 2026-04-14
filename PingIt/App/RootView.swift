import SwiftUI

struct RootView: View {
    @Environment(AuthService.self) private var authService

    var body: some View {
        Group {
            if authService.currentUser != nil {
                MainTabView()
            } else {
                AuthenticationCoordinatorView()
            }
        }
        .animation(.default, value: authService.currentUser != nil)
    }
}
