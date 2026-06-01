import Foundation

@Observable
@MainActor
final class OnboardingViewModel {
    var currentPage = 0
    private(set) var isComplete = false
    private(set) var isSubmitting = false
    private(set) var errorMessage: String?

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

    /// Mark the local state as complete without writing to the server. Used as
    /// an escape hatch when the Firestore write keeps failing (offline, rules,
    /// or a stale user doc); the next launch will re-attempt the write.
    func forceLocalComplete() {
        isComplete = true
    }

    func clearError() {
        errorMessage = nil
    }

    private func completeOnboarding() async {
        guard let userId, let userService else {
            errorMessage = "We couldn't reach your account. Tap Continue Anyway to enter the app."
            return
        }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            try await userService.mergeUser(id: userId, data: ["hasCompletedOnboarding": true])
            analyticsService?.logEvent("onboarding_completed", parameters: nil)
            isComplete = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
