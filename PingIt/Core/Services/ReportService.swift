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
