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
}
