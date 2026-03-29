import SwiftUI

struct SettingsPlaceholderView: View {
    @Environment(AuthService.self) private var authService

    var body: some View {
        NavigationStack {
            List {
                Button("Sign Out", role: .destructive) {
                    try? authService.signOut()
                }
            }
            .navigationTitle("Settings")
        }
    }
}
