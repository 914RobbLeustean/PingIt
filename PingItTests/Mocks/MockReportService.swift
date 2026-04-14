import Observation
@testable import PingIt

@Observable
@MainActor
final class MockReportService: ReportServicing {
    var errorToThrow: Error?
    var submitReportCalled = false
    var lastTargetType: Report.ReportTargetType?
    var lastTargetId: String?
    var lastReason: Report.ReportReason?

    func submitReport(
        targetType: Report.ReportTargetType,
        targetId: String,
        targetOwnerId: String,
        reason: Report.ReportReason,
        details: String?
    ) async throws {
        submitReportCalled = true
        lastTargetType = targetType
        lastTargetId = targetId
        lastReason = reason
        if let error = errorToThrow { throw error }
    }
}
