import Foundation
import FirebaseFirestore

/// Post-event recap for an expired ping. Created server-side by the
/// expirePings cron; carries the attendee snapshot (users who RSVP'd plus
/// the creator) because the rsvps docs are deleted when the ping is
/// cleaned up.
struct PingRecap: Codable, Identifiable, Hashable, Sendable {

    static func == (lhs: PingRecap, rhs: PingRecap) -> Bool {
        lhs.id == rhs.id && lhs.photoCount == rhs.photoCount
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    @DocumentID var id: String?
    var pingId: String
    var title: String
    var category: String?
    var location: GeoPoint
    var attendeeIds: [String]
    var photoCount: Int? = 0
    var expiresAt: Date
    var recapWindowClosesAt: Date
    var ghostExpiresAt: Date
    @ServerTimestamp var createdAt: Date?

    var visiblePhotoCount: Int {
        photoCount ?? 0
    }

    func canSubmitPhotos(userId: String, now: Date) -> Bool {
        attendeeIds.contains(userId) && recapWindowClosesAt > now
    }

    /// Empty recaps stay hidden from people who weren't there — a ghost
    /// with no photos is map clutter. Attendees always see it so they can
    /// add the first photo.
    func isVisibleOnMap(to userId: String?) -> Bool {
        if visiblePhotoCount > 0 { return true }
        guard let userId else { return false }
        return attendeeIds.contains(userId)
    }
}
