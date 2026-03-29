import SwiftUI
import FirebaseCore

@main
struct PingItApp: App {
    static let configuredFirebase: Void = { FirebaseApp.configure() }()

    @State private var authService = { _ = PingItApp.configuredFirebase; return AuthService() }()
    @State private var pingService = PingService()
    @State private var locationService = LocationService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authService)
                .environment(pingService)
                .environment(locationService)
        }
    }
}
