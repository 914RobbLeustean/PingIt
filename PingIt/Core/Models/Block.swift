import Foundation
import FirebaseFirestore

struct Block: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var blockerId: String
    var blockedUserId: String
    @ServerTimestamp var createdAt: Date?
}
