import Foundation
import Testing
@testable import PingIt

@Suite("OnboardingViewModel")
@MainActor
struct OnboardingViewModelTests {

    private func makeVM(
        userService: MockUserService? = nil,
        analyticsService: MockAnalyticsService? = nil,
        userId: String = "user1"
    ) -> (OnboardingViewModel, MockUserService, MockAnalyticsService) {
        let userService = userService ?? MockUserService()
        let analyticsService = analyticsService ?? MockAnalyticsService()
        let vm = OnboardingViewModel()
        vm.configure(userService: userService, analyticsService: analyticsService, userId: userId)
        return (vm, userService, analyticsService)
    }

    // MARK: - Page Navigation

    @Test("advance increments page from 0 to 1")
    func advanceIncrementsPage() async {
        let (vm, _, _) = makeVM()
        #expect(vm.currentPage == 0)

        await vm.advance()
        #expect(vm.currentPage == 1)
    }

    @Test("advance increments page from 1 to 2")
    func advanceToLastPage() async {
        let (vm, _, _) = makeVM()
        vm.currentPage = 1

        await vm.advance()
        #expect(vm.currentPage == 2)
    }

    @Test("advance on last page completes onboarding")
    func advanceOnLastPageCompletes() async {
        let (vm, userService, _) = makeVM()
        vm.currentPage = OnboardingViewModel.pageCount - 1

        await vm.advance()
        #expect(vm.isComplete)
        #expect(userService.updateUserCalled)
        #expect(userService.lastUpdateData?["hasCompletedOnboarding"] as? Bool == true)
    }

    // MARK: - Skip

    @Test("skip completes onboarding")
    func skipCompletes() async {
        let (vm, userService, _) = makeVM()

        await vm.skip()
        #expect(vm.isComplete)
        #expect(userService.updateUserCalled)
        #expect(userService.lastUpdateData?["hasCompletedOnboarding"] as? Bool == true)
    }

    @Test("skip from first page completes onboarding")
    func skipFromFirstPage() async {
        let (vm, _, _) = makeVM()
        #expect(vm.currentPage == 0)

        await vm.skip()
        #expect(vm.isComplete)
    }

    // MARK: - Analytics

    @Test("completion logs analytics event")
    func completionLogsAnalytics() async {
        let (vm, _, analyticsService) = makeVM()

        await vm.skip()
        #expect(analyticsService.loggedEvents.count == 1)
        #expect(analyticsService.loggedEvents.first?.name == "onboarding_completed")
    }

    // MARK: - Error Handling

    @Test("completion does not set isComplete on error")
    func completionHandlesError() async {
        let userService = MockUserService()
        userService.errorToThrow = NSError(domain: "test", code: 1)
        let (vm, _, _) = makeVM(userService: userService)

        await vm.skip()
        #expect(!vm.isComplete)
    }

    // MARK: - Initial State

    @Test("initial state is page 0, not complete")
    func initialState() {
        let (vm, _, _) = makeVM()
        #expect(vm.currentPage == 0)
        #expect(!vm.isComplete)
    }

    @Test("page count is 3")
    func pageCount() {
        #expect(OnboardingViewModel.pageCount == 3)
    }
}
