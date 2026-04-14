import SwiftUI
import FirebaseCore

@main
struct PingItApp: App {
    static let configuredFirebase: Void = { FirebaseApp.configure() }()

    @State private var authService = { _ = PingItApp.configuredFirebase; return AuthService() }()
    @State private var pingService = PingService()
    @State private var chatService = ChatService()
    @State private var userService = UserService()
    @State private var locationService = LocationService()
    @State private var contentModerationService = ContentModerationService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authService)
                .environment(pingService)
                .environment(chatService)
                .environment(userService)
                .environment(locationService)
                .environment(contentModerationService)
        }
    }
}
