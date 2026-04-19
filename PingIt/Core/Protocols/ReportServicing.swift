import Foundation

protocol ReportServicing {
    func submitReport(
        targetType: Report.ReportTargetType,
        targetId: String,
        targetOwnerId: String,
        reason: Report.ReportReason,
        details: String?
    ) async throws
}
