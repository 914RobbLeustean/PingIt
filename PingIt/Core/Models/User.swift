import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var username: String
    var email: String
    var usernameLowercase: String
    var profileImageUrl: String?
    @ServerTimestamp var createdAt: Date?
    var blockedUsers: [String] = []
    var isPrivateProfile: Bool = false
    var notifyNearbyPings: Bool = true
    var notifyHotPings: Bool = true
    // Optional so user docs created before the social feature still decode.
    var notifyFollowActivity: Bool?
    var followerCount: Int?
    var followingCount: Int?
    var fcmToken: String?
    var lastKnownLocation: [String: Double]?
    var hasCompletedOnboarding: Bool?
    var suspensionStatus: String?
    var suspensionExpiresAt: Date?
}
