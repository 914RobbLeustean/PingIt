import Foundation
import FirebaseFirestore

struct PingRecapPhoto: Codable, Identifiable, Hashable, Sendable {
    @DocumentID var id: String?
    var pingId: String
    var submitterId: String
    var imageUrl: String
    @ServerTimestamp var createdAt: Date?
    var isModerated: Bool = false
}
