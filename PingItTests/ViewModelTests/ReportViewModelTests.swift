import Testing
@testable import PingIt

@Suite("ReportViewModel Tests")
@MainActor
struct ReportViewModelTests {
    @Test("Successful report submission")
    func submitReportSucceeds() async {
        let mockReport = MockReportService()
        let vm = ReportViewModel(
            targetType: .ping,
            targetId: "ping1",
            targetOwnerId: "user2"
        )
        vm.configure(reportService: mockReport)
        vm.selectedReason = .spam

        await vm.submitReport()

        #expect(vm.didSubmitReport == true)
        #expect(mockReport.submitReportCalled == true)
        #expect(mockReport.lastReason == .spam)
    }

    @Test("Report requires reason selection")
    func reportRequiresReason() async {
        let mockReport = MockReportService()
        let vm = ReportViewModel(
            targetType: .ping,
            targetId: "ping1",
            targetOwnerId: "user2"
        )
        vm.configure(reportService: mockReport)
        // selectedReason is nil by default

        await vm.submitReport()

        #expect(vm.didSubmitReport == false)
        #expect(vm.errorMessage != nil)
    }

    @Test("Offers block after report")
    func offersBlockAfterReport() async {
        let mockReport = MockReportService()
        let vm = ReportViewModel(
            targetType: .ping,
            targetId: "ping1",
            targetOwnerId: "user2"
        )
        vm.configure(reportService: mockReport)
        vm.selectedReason = .harassment

        await vm.submitReport()

        #expect(vm.showBlockOffer == true)
    }
}
