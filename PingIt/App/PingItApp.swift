import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
struct PingItApp: App {
    static let configuredFirebase: Void = {
        FirebaseApp.configure()
        ServerTime.startObserving()
    }()

    @State private var authService = { _ = PingItApp.configuredFirebase; return AuthService() }()
    @State private var pingService = PingService()
    @State private var chatService = ChatService()
    @State private var userService = UserService()
    @State private var locationService = LocationService()
    @State private var contentModerationService = ContentModerationService()
    @State private var blockService = BlockService()
    @State private var reportService = ReportService()
    @State private var rateLimitService = RateLimitService()
    @State private var notificationService = NotificationService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authService)
                .environment(pingService)
                .environment(chatService)
                .environment(userService)
                .environment(locationService)
                .environment(contentModerationService)
                .environment(blockService)
                .environment(reportService)
                .environment(rateLimitService)
                .environment(notificationService)
                .onChange(of: authService.currentUser == nil) {
                    if authService.currentUser == nil {
                        blockService.stopObserving()
                        rateLimitService.resetForSignOut()
                    }
                }
                .task {
                    UNUserNotificationCenter.current().delegate = notificationService
                    Messaging.messaging().delegate = notificationService
                    let granted = await notificationService.requestPermission()
                    if granted {
                        await notificationService.registerFCMToken()
                    }
                }
        }
    }
}
