import Foundation
import FirebaseFirestore

struct Boost: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var pingId: String
    var userId: String
    @ServerTimestamp var createdAt: Date?
}
