import SwiftUI
import FirebaseAuth

struct ProfilePlaceholderView: View {
    @Environment(AuthService.self) private var authService

    var body: some View {
        NavigationStack {
            VStack {
                Text("Signed in as:")
                Text(authService.currentUser?.email ?? "Unknown")
                    .font(.headline)
            }
            .navigationTitle("Profile")
        }
    }
}
