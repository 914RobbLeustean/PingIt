import Foundation
import FirebaseFirestore

struct ChatParticipant: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var chatId: String
    var userId: String
    @ServerTimestamp var joinedAt: Date?
    var leftAt: Date?
}
