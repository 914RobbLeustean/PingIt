import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var username: String
    var email: String
    var profileImageUrl: String?
    @ServerTimestamp var createdAt: Date?
    var blockedUsers: [String] = []
}
