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
    var boostCount: Int = 0
    var participantCount: Int = 0
    var chatId: String?
    @ServerTimestamp var createdAt: Date?

    var hotScore: Double {
        Double(boostCount) * 2.0 + Double(participantCount) + max(0, expiresAt.timeIntervalSinceNow / 3600.0) * 0.5
    }

    var isHot: Bool {
        hotScore >= 5.0
    }

    enum PingStatus: String, Codable, Sendable {
        case active
        case expired
        case removed
    }
}
