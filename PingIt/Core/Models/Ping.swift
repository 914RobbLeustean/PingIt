import Foundation
import FirebaseFirestore

struct Ping: Codable, Identifiable, Hashable, Sendable {

    static func == (lhs: Ping, rhs: Ping) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    @DocumentID var id: String?
    var creatorId: String
    var text: String
    var location: GeoPoint
    var geohash: String
    var expiresAt: Date
    var status: PingStatus
    var chatId: String?
    @ServerTimestamp var createdAt: Date?

    enum PingStatus: String, Codable, Sendable {
        case active
        case expired
        case removed
    }
}
