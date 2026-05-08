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
    @State private var analyticsService = AnalyticsService()
    @State private var crashReportingService = CrashReportingService()
    @State private var performanceService = PerformanceService()
    @State private var navigationRouter = NavigationRouter()

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
                .environment(analyticsService)
                .environment(crashReportingService)
                .environment(performanceService)
                .environment(navigationRouter)
                .onChange(of: authService.currentUser?.uid) { _, newUid in
                    if let uid = newUid {
                        analyticsService.setUserId(uid)
                        crashReportingService.setUserId(uid)
                    } else {
                        analyticsService.setUserId(nil)
                        crashReportingService.setUserId(nil)
                        blockService.stopObserving()
                        rateLimitService.resetForSignOut()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .init("PingItOpenPing"))) { notification in
                    if let pingId = notification.userInfo?["pingId"] as? String {
                        navigationRouter.pendingPingId = pingId
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
