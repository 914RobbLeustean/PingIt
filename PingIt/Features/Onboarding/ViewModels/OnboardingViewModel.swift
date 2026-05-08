import Foundation

@Observable
@MainActor
final class OnboardingViewModel {
    var currentPage = 0
    private(set) var isComplete = false

    static let pageCount = 3

    private var userService: (any UserServicing)?
    private var analyticsService: (any AnalyticsServicing)?
    private var userId: String?

    func configure(userService: any UserServicing, analyticsService: any AnalyticsServicing, userId: String) {
        self.userService = userService
        self.analyticsService = analyticsService
        self.userId = userId
    }

    func advance() async {
        if currentPage < Self.pageCount - 1 {
            currentPage += 1
        } else {
            await completeOnboarding()
        }
    }

    func skip() async {
        await completeOnboarding()
    }

    private func completeOnboarding() async {
        guard let userId, let userService else { return }
        do {
            try await userService.updateUser(id: userId, data: ["hasCompletedOnboarding": true])
            analyticsService?.logEvent("onboarding_completed", parameters: nil)
            isComplete = true
        } catch {
            // Silently fail — user can retry or skip
        }
    }
}
