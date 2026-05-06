import FirebaseAnalytics

@Observable
@MainActor
final class AnalyticsService: AnalyticsServicing {

    enum EventName {
        static let pingCreated = "ping_created"
        static let chatJoined = "chat_joined"
        static let boostUsed = "boost_used"
        static let onboardingCompleted = "onboarding_completed"
    }

    enum ParameterName {
        static let durationType = "duration_type"
        static let durationHours = "duration_hours"
    }

    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
    }

    func setUserId(_ userId: String?) {
        Analytics.setUserID(userId)
    }
}
