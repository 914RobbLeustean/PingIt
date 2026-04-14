import Foundation
import FirebaseAuth
import FirebaseFirestore

@Observable
@MainActor
final class ReportService: ReportServicing {
    private let db = Firestore.firestore()

    func submitReport(
        targetType: Report.ReportTargetType,
        targetId: String,
        targetOwnerId: String,
        reason: Report.ReportReason,
        details: String?
    ) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw PingItError.notAuthenticated
        }

        // Prevent duplicate reports from the same user on the same target
        let existing = try await db
            .collection(Constants.Firestore.reportsCollection)
            .whereField("reporterId", isEqualTo: currentUserId)
            .whereField("targetId", isEqualTo: targetId)
            .limit(to: 1)
            .getDocuments()

        guard existing.documents.isEmpty else {
            throw PingItError.reportAlreadySubmitted
        }

        let report = Report(
            reporterId: currentUserId,
            targetType: targetType,
            targetId: targetId,
            targetOwnerId: targetOwnerId,
            reason: reason,
            details: details,
            status: .pending
        )

        do {
            try db.collection(Constants.Firestore.reportsCollection)
                .addDocument(from: report)
        } catch {
            throw PingItError.reportFailed(underlying: error)
        }
    }
}
