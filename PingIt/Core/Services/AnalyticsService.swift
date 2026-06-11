import FirebaseAnalytics

@Observable
@MainActor
final class AnalyticsService: AnalyticsServicing {

    enum EventName {
        static let pingCreated = "ping_created"
        static let chatJoined = "chat_joined"
        static let boostUsed = "boost_used"
        static let onboardingCompleted = "onboarding_completed"
        static let reactionToggled = "reaction_toggled"
        static let locationShared = "location_shared"
        static let feedViewed = "feed_viewed"
        static let feedSortChanged = "feed_sort_changed"
        static let pingShared = "ping_shared"
        static let rsvpToggled = "rsvp_toggled"
        static let pingEdited = "ping_edited"
    }

    enum ParameterName {
        static let durationType = "duration_type"
        static let durationHours = "duration_hours"
        static let hasImage = "has_image"
        static let pingId = "ping_id"
        static let category = "category"
        static let isHot = "is_hot"
        static let isAttending = "is_attending"
    }

    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
    }

    func setUserId(_ userId: String?) {
        Analytics.setUserID(userId)
    }
}
