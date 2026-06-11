import Foundation
import FirebaseFirestore

struct Chat: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var pingId: String
    var participantCount: Int = 0
    var lastMessageAt: Date?
    @ServerTimestamp var createdAt: Date?
}
