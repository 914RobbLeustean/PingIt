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
    @State private var imageStorageService = ImageStorageService()
    @State private var dataExportService = DataExportService()
    @State private var pingRecapService = PingRecapService()
    @State private var followService = FollowService()
    @State private var navigationRouter = NavigationRouter()
    @State private var isShowingSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()

                if isShowingSplash {
                    SplashView {
                        withAnimation(.easeOut(duration: 0.55)) {
                            isShowingSplash = false
                        }
                    }
                    // Fade while scaling slightly past the viewer — reads as
                    // the camera pushing through the splash into the app.
                    .transition(
                        UIAccessibility.isReduceMotionEnabled
                            ? .opacity
                            : .opacity.combined(with: .scale(scale: 1.08))
                    )
                    .zIndex(1)
                }
            }
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
            .environment(imageStorageService)
            .environment(dataExportService)
            .environment(pingRecapService)
            .environment(followService)
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
            .onReceive(NotificationCenter.default.publisher(for: .init("PingItOpenRecap"))) { notification in
                if let recapId = notification.userInfo?["recapId"] as? String {
                    navigationRouter.pendingRecapId = recapId
                }
            }
            .onOpenURL { url in
                if case .ping(let pingId) = DeepLink(url: url) {
                    navigationRouter.pendingPingId = pingId
                }
            }
            .task {
                FontRegistrationCheck.run()
                UNUserNotificationCenter.current().delegate = notificationService
                Messaging.messaging().delegate = notificationService
                let granted = await notificationService.requestPermission()
                if granted {
                    await notificationService.registerFCMToken()
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
