import Foundation
import FirebaseFirestore

struct Ping: Codable, Identifiable, Hashable, Sendable {

    static func == (lhs: Ping, rhs: Ping) -> Bool {
        lhs.id == rhs.id
        && lhs.creatorId == rhs.creatorId
        && lhs.text == rhs.text
        && lhs.description == rhs.description
        && lhs.status == rhs.status
        && lhs.boostCount == rhs.boostCount
        && lhs.participantCount == rhs.participantCount
        && lhs.imageUrl == rhs.imageUrl
        && lhs.expiresAt == rhs.expiresAt
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    @DocumentID var id: String?
    var creatorId: String
    var text: String
    var description: String?
    var category: String?
    var location: GeoPoint
    var geohash: String
    var expiresAt: Date
    var status: PingStatus
    var boostCount: Int = 0
    var participantCount: Int = 0
    var chatId: String?
    var imageUrl: String?
    @ServerTimestamp var createdAt: Date?

    var hotScore: Double {
        let timeContribution = min(max(0, expiresAt.timeIntervalSinceNow / 3600.0) * 0.1, 2.0)
        return Double(boostCount) * 2.0 + Double(participantCount) + timeContribution
    }

    var isHot: Bool {
        boostCount >= 3 && hotScore >= 8.0
    }

    enum PingStatus: String, Codable, Sendable {
        case active
        case expired
        case removed
    }
}
