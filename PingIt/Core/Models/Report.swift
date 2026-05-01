import Foundation
import FirebaseFirestore

struct Report: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var reporterId: String
    var targetType: ReportTargetType
    var targetId: String
    var targetOwnerId: String
    var reason: ReportReason
    var details: String?
    var status: ReportStatus
    var targetContent: String?
    var targetImageURL: String?
    @ServerTimestamp var createdAt: Date?

    enum ReportTargetType: String, Codable, Sendable {
        case ping
        case message
    }

    enum ReportReason: String, Codable, Sendable, CaseIterable {
        case spam = "Spam"
        case harassment = "Harassment"
        case inappropriateContent = "Inappropriate Content"
        case other = "Other"
    }

    enum ReportStatus: String, Codable, Sendable {
        case pending
        case reviewed
        case dismissed
    }
}
