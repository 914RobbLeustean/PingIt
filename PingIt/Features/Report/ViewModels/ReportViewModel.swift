import Foundation

@Observable
@MainActor
final class ReportViewModel {
    private var reportService: (any ReportServicing)?
    private var isConfigured = false

    let targetType: Report.ReportTargetType
    let targetId: String
    let targetOwnerId: String

    var selectedReason: Report.ReportReason?
    var additionalDetails = ""
    private(set) var isSubmitting = false
    private(set) var didSubmitReport = false
    private(set) var showBlockOffer = false
    private(set) var errorMessage: String?

    init(targetType: Report.ReportTargetType, targetId: String, targetOwnerId: String) {
        self.targetType = targetType
        self.targetId = targetId
        self.targetOwnerId = targetOwnerId
    }

    func configure(reportService: any ReportServicing) {
        guard !isConfigured else { return }
        self.reportService = reportService
        isConfigured = true
    }

    func submitReport() async {
        guard let reportService else { return }

        guard let reason = selectedReason else {
            errorMessage = "Please select a reason for your report."
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let details = additionalDetails.trimmingCharacters(in: .whitespacesAndNewlines)
            try await reportService.submitReport(
                targetType: targetType,
                targetId: targetId,
                targetOwnerId: targetOwnerId,
                reason: reason,
                details: details.isEmpty ? nil : details
            )
            didSubmitReport = true
            showBlockOffer = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
