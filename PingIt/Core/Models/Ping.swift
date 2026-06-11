import Foundation
import FirebaseFirestore

struct Ping: Codable, Identifiable, Hashable, Sendable {

    static func == (lhs: Ping, rhs: Ping) -> Bool {
        lhs.id == rhs.id
        && lhs.creatorId == rhs.creatorId
        && lhs.text == rhs.text
        && lhs.description == rhs.description
        && lhs.category == rhs.category
        && lhs.status == rhs.status
        && lhs.boostCount == rhs.boostCount
        && lhs.rsvpCount == rhs.rsvpCount
        && lhs.participantCount == rhs.participantCount
        && lhs.imageUrl == rhs.imageUrl
        && lhs.expiresAt == rhs.expiresAt
        && lhs.editedAt == rhs.editedAt
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
    // Optional so pings created before the RSVP feature still decode.
    var rsvpCount: Int? = 0
    var participantCount: Int = 0
    var chatId: String?
    var imageUrl: String?
    @ServerTimestamp var createdAt: Date?
    // Set by the updatePing callable; nil for never-edited pings.
    var editedAt: Date?

    var attendingCount: Int {
        rsvpCount ?? 0
    }

    var hotScore: Double {
        // ServerTime, not the device clock — hot ranking must agree across
        // devices like every other time computation in the app.
        let remaining = expiresAt.timeIntervalSince(ServerTime.now)
        let timeContribution = min(max(0, remaining / 3600.0) * 0.1, 2.0)
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
