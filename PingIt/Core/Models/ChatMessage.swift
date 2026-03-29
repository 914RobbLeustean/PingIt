import Foundation
import FirebaseFirestore

struct ChatMessage: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var chatId: String
    var senderId: String
    var text: String
    @ServerTimestamp var createdAt: Date?
    var isModerated: Bool = false
}
