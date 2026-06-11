import Foundation
import Testing
import FirebaseFirestore
@testable import PingIt

@Suite("EditPingViewModel")
@MainActor
struct EditPingViewModelTests {

    // MARK: - Helpers

    private func makePing(
        text: String = "Pickup game at the park",
        description: String? = "Bring water",
        category: String? = "sports"
    ) -> Ping {
        var ping = Ping(
            creatorId: "creator1",
            text: text,
            description: description,
            category: category,
            location: GeoPoint(latitude: 46.77, longitude: 23.62),
            geohash: "",
            expiresAt: Date.now.addingTimeInterval(3600),
            status: .active
        )
        ping.id = "ping-test-1"
        return ping
    }

    private func makeVM(
        ping: Ping? = nil,
        pingService: MockPingService? = nil,
        moderationService: MockContentModerationService? = nil,
        analyticsService: MockAnalyticsService? = nil
    ) -> EditPingViewModel {
        let vm = EditPingViewModel(ping: ping ?? makePing())
        vm.configure(
            pingService: pingService ?? MockPingService(),
            contentModerationService: moderationService ?? MockContentModerationService(),
            analyticsService: analyticsService
        )
        return vm
    }

    // MARK: - Prefill

    @Test func prefillsFieldsFromPing() {
        let vm = makeVM()
        #expect(vm.text == "Pickup game at the park")
        #expect(vm.descriptionText == "Bring water")
        #expect(vm.selectedCategory == .sports)
    }

    @Test func prefillsEmptyDescriptionWhenNil() {
        let vm = makeVM(ping: makePing(description: nil))
        #expect(vm.descriptionText.isEmpty)
    }

    // MARK: - canSave gating

    @Test func cannotSaveWithoutChanges() {
        let vm = makeVM()
        #expect(!vm.hasChanges)
        #expect(!vm.canSave)
    }

    @Test func canSaveAfterTextChange() {
        let vm = makeVM()
        vm.text = "Pickup game moved to the gym"
        #expect(vm.hasChanges)
        #expect(vm.canSave)
    }

    @Test func canSaveAfterCategoryOnlyChange() {
        let vm = makeVM()
        vm.selectedCategory = .chill
        #expect(vm.canSave)
    }

    @Test func cannotSaveEmptyText() {
        let vm = makeVM()
        vm.text = "   "
        #expect(!vm.canSave)
    }

    @Test func cannotSaveOverLimitText() {
        let vm = makeVM()
        vm.text = String(repeating: "a", count: Constants.Ping.maxTextLength + 1)
        #expect(!vm.canSave)
    }

    @Test func cannotSaveWithoutCategory() {
        let vm = makeVM()
        vm.text = "Changed"
        vm.selectedCategory = nil
        #expect(!vm.canSave)
    }

    // MARK: - Save

    @Test func saveSendsTrimmedFieldsToService() async {
        let pingService = MockPingService()
        let vm = makeVM(pingService: pingService)
        vm.text = "  Moved to the gym  "
        vm.descriptionText = "  New details  "
        vm.selectedCategory = .chill

        await vm.save()

        #expect(pingService.updatePingCalled)
        #expect(pingService.lastUpdatedPingId == "ping-test-1")
        #expect(pingService.lastUpdatedText == "Moved to the gym")
        #expect(pingService.lastUpdatedDescription == "New details")
        #expect(pingService.lastUpdatedCategory == "chill")
        #expect(vm.didSave)
        #expect(vm.errorMessage == nil)
    }

    @Test func saveSendsNilForClearedDescription() async {
        let pingService = MockPingService()
        let vm = makeVM(pingService: pingService)
        vm.descriptionText = ""
        vm.text = "Changed text"

        await vm.save()

        #expect(pingService.lastUpdatedDescription == nil)
    }

    @Test func saveBlockedByModeration() async {
        let pingService = MockPingService()
        let moderation = MockContentModerationService()
        moderation.resultToReturn = .blocked(reason: "inappropriate")
        let vm = makeVM(pingService: pingService, moderationService: moderation)
        vm.text = "Changed text"

        await vm.save()

        #expect(!pingService.updatePingCalled)
        #expect(!vm.didSave)
        #expect(vm.errorMessage != nil)
    }

    @Test func saveSurfacesServiceError() async {
        let pingService = MockPingService()
        pingService.errorToThrow = PingItError.firestoreWriteFailed(
            underlying: NSError(domain: "test", code: 1)
        )
        let vm = makeVM(pingService: pingService)
        vm.text = "Changed text"

        await vm.save()

        #expect(!vm.didSave)
        #expect(vm.errorMessage != nil)
    }

    @Test func saveLogsAnalyticsEvent() async {
        let analytics = MockAnalyticsService()
        let vm = makeVM(analyticsService: analytics)
        vm.text = "Changed text"

        await vm.save()

        #expect(analytics.loggedEvents.contains { $0.name == AnalyticsService.EventName.pingEdited })
    }
}
