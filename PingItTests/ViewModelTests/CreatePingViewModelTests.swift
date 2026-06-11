import Foundation
import Testing
import CoreLocation
import FirebaseFirestore
import UIKit
@testable import PingIt

@Suite("CreatePingViewModel")
@MainActor
struct CreatePingViewModelTests {

    // MARK: - Helpers

    private func makeVM(
        authService: MockAuthService? = nil,
        pingService: MockPingService? = nil,
        chatService: MockChatService? = nil,
        locationService: MockLocationService? = nil,
        contentModerationService: MockContentModerationService? = nil,
        rateLimitService: MockRateLimitService? = nil
    ) -> CreatePingViewModel {
        let authService = authService ?? MockAuthService()
        let pingService = pingService ?? MockPingService()
        let chatService = chatService ?? MockChatService()
        let locationService = locationService ?? MockLocationService()
        let contentModerationService = contentModerationService ?? MockContentModerationService()
        let rateLimitService = rateLimitService ?? MockRateLimitService()
        let vm = CreatePingViewModel()
        vm.configure(
            authService: authService,
            pingService: pingService,
            chatService: chatService,
            locationService: locationService,
            contentModerationService: contentModerationService,
            rateLimitService: rateLimitService
        )
        return vm
    }

    private func authenticatedAuth(uid: String = "user1") -> MockAuthService {
        let auth = MockAuthService()
        auth.currentUser = MockAuthUser(uid: uid, isEmailVerified: true)
        auth.isEmailVerified = true
        return auth
    }

    private let clujCoordinate = CLLocationCoordinate2D(
        latitude: Constants.Cluj.centerLatitude,
        longitude: Constants.Cluj.centerLongitude
    )

    // MARK: - canCreate

    @Test func canCreateFalseWithNoText() {
        let vm = makeVM(authService: authenticatedAuth())
        vm.selectedLocation = clujCoordinate
        vm.text = ""
        #expect(vm.canCreate == false)
    }

    @Test func canCreateFalseWithWhitespaceOnlyText() {
        let vm = makeVM(authService: authenticatedAuth())
        vm.selectedLocation = clujCoordinate
        vm.text = "   "
        #expect(vm.canCreate == false)
    }

    @Test func canCreateFalseWithNoLocation() {
        let vm = makeVM(authService: authenticatedAuth())
        vm.text = "Hello Cluj"
        vm.selectedLocation = nil
        #expect(vm.canCreate == false)
    }

    // MARK: - characterCount / isOverLimit

    @Test func characterCountMatchesTextLength() {
        let vm = makeVM()
        vm.text = "Hello"
        #expect(vm.characterCount == 5)
    }

    @Test func isOverLimitFalseUnderMax() {
        let vm = makeVM()
        vm.text = String(repeating: "a", count: Constants.Ping.maxTextLength)
        #expect(vm.isOverLimit == false)
    }

    @Test func isOverLimitTrueOverMax() {
        let vm = makeVM()
        vm.text = String(repeating: "a", count: Constants.Ping.maxTextLength + 1)
        #expect(vm.isOverLimit)
    }

    // MARK: - createPing success

    @Test func createPingSuccessSetDidCreatePing() async {
        let auth = authenticatedAuth()
        let ping = MockPingService()
        let location = MockLocationService()
        location.boundaryResult = true
        let vm = makeVM(authService: auth, pingService: ping, locationService: location)
        vm.text = "Study session at BT"
        vm.selectedLocation = clujCoordinate

        await vm.createPing()

        #expect(vm.didCreatePing)
        #expect(ping.createPingWithChatCalled)
        #expect(vm.errorMessage == nil)
    }

    // MARK: - Email verification gate

    @Test("Unverified email prevents ping creation")
    func unverifiedEmailCannotCreatePing() async {
        let mockAuth = MockAuthService()
        mockAuth.currentUser = MockAuthUser(uid: "user1", isEmailVerified: false)
        mockAuth.isEmailVerified = false
        let mockPing = MockPingService()
        let mockChat = MockChatService()
        let mockLocation = MockLocationService()
        mockLocation.boundaryResult = true

        let vm = CreatePingViewModel()
        vm.configure(authService: mockAuth, pingService: mockPing, chatService: mockChat, locationService: mockLocation, contentModerationService: MockContentModerationService(), rateLimitService: MockRateLimitService())
        vm.text = "Test ping"
        vm.selectedLocation = Constants.Cluj.center

        await vm.createPing()

        #expect(vm.didCreatePing == false)
        #expect(vm.errorMessage != nil)
        #expect(mockPing.createPingWithChatCalled == false)
    }

    // MARK: - createPing failures

    @Test func createPingFailsWhenNotAuthenticated() async {
        let auth = MockAuthService()
        auth.currentUser = nil
        let vm = makeVM(authService: auth)
        vm.text = "Test ping"
        vm.selectedLocation = clujCoordinate

        await vm.createPing()

        #expect(vm.didCreatePing == false)
        #expect(vm.errorMessage != nil)
    }

    @Test func createPingFailsWhenOutsideBoundary() async {
        let auth = authenticatedAuth()
        let location = MockLocationService()
        location.boundaryResult = false
        let vm = makeVM(authService: auth, locationService: location)
        vm.text = "Ping outside Cluj"
        vm.selectedLocation = CLLocationCoordinate2D(latitude: 44.42, longitude: 26.10)

        await vm.createPing()

        #expect(vm.didCreatePing == false)
        #expect(vm.errorMessage != nil)
    }

    @Test func createPingFailsWithEmptyText() async {
        let auth = authenticatedAuth()
        let location = MockLocationService()
        location.boundaryResult = true
        let vm = makeVM(authService: auth, locationService: location)
        vm.text = "   "
        vm.selectedLocation = clujCoordinate

        await vm.createPing()

        #expect(vm.didCreatePing == false)
        #expect(vm.errorMessage != nil)
    }

    @Test func createPingFailsWhenTextTooLong() async {
        let auth = authenticatedAuth()
        let location = MockLocationService()
        location.boundaryResult = true
        let vm = makeVM(authService: auth, locationService: location)
        vm.text = String(repeating: "x", count: Constants.Ping.maxTextLength + 1)
        vm.selectedLocation = clujCoordinate

        await vm.createPing()

        #expect(vm.didCreatePing == false)
        #expect(vm.errorMessage != nil)
    }

    @Test func createPingPropagatesServiceError() async {
        let auth = authenticatedAuth()
        let ping = MockPingService()
        ping.errorToThrow = PingItError.firestoreWriteFailed(underlying: URLError(.notConnectedToInternet))
        let location = MockLocationService()
        location.boundaryResult = true
        let vm = makeVM(authService: auth, pingService: ping, locationService: location)
        vm.text = "Test ping"
        vm.selectedLocation = clujCoordinate

        await vm.createPing()

        #expect(vm.didCreatePing == false)
        #expect(vm.errorMessage != nil)
    }

    // MARK: - Content Moderation

    @Test("Moderated text prevents ping creation")
    func moderatedTextBlocksPingCreation() async {
        let mockAuth = MockAuthService()
        mockAuth.currentUser = MockAuthUser(uid: "user1", isEmailVerified: true)
        mockAuth.isEmailVerified = true
        let mockPing = MockPingService()
        let mockChat = MockChatService()
        let mockLocation = MockLocationService()
        mockLocation.boundaryResult = true
        let mockModeration = MockContentModerationService()
        mockModeration.resultToReturn = .blocked(reason: "Violates community guidelines.")

        let vm = CreatePingViewModel()
        vm.configure(
            authService: mockAuth,
            pingService: mockPing,
            chatService: mockChat,
            locationService: mockLocation,
            contentModerationService: mockModeration,
            rateLimitService: MockRateLimitService()
        )
        vm.text = "Bad content"
        vm.selectedLocation = Constants.Cluj.center

        await vm.createPing()

        #expect(vm.didCreatePing == false)
        #expect(vm.errorMessage != nil)
        #expect(mockModeration.checkCalled == true)
        #expect(mockPing.createPingWithChatCalled == false)
    }

    // MARK: - Custom Duration

    @Test func presetExpirationReturnsCorrectDuration() {
        let vm = makeVM()
        vm.selectedExpirationIndex = 0
        #expect(vm.selectedExpiration == 6 * 3600)

        vm.selectedExpirationIndex = 1
        #expect(vm.selectedExpiration == 24 * 3600)

        vm.selectedExpirationIndex = 2
        #expect(vm.selectedExpiration == 48 * 3600)
    }

    @Test func customExpiryMatchesSelectedSlot() {
        let vm = makeVM()
        vm.isCustomDuration = true
        vm.customExpirySlotIndex = 4
        let slots = vm.customExpirySlots
        #expect(vm.customExpiryDate == slots[4])
        let expected = slots[4].timeIntervalSince(Date.now)
        #expect(abs(vm.selectedExpiration - expected) < 2)
    }

    @Test func customExpirySlotIndexClampedToFirstSlot() {
        let vm = makeVM()
        vm.isCustomDuration = true
        vm.customExpirySlotIndex = -5
        #expect(vm.customExpiryDate == vm.customExpirySlots.first)
    }

    @Test func customExpirySlotIndexClampedToLastSlot() {
        let vm = makeVM()
        vm.isCustomDuration = true
        vm.customExpirySlotIndex = vm.customExpirySlots.count + 100
        #expect(vm.customExpiryDate == vm.customExpirySlots.last)
        // Last slot never exceeds the 48h maximum
        #expect(vm.selectedExpiration <= Constants.Ping.customDurationMax)
    }

    // MARK: - Image Attachments

    @Test func createPingWithImageCallsUpload() async {
        let auth = authenticatedAuth()
        let ping = MockPingService()
        let location = MockLocationService()
        location.boundaryResult = true
        let vm = makeVM(authService: auth, pingService: ping, locationService: location)
        vm.text = "Ping with photo"
        vm.selectedLocation = clujCoordinate
        let tinyImage = UIImage(systemName: "circle.fill")!
        vm.handleCameraImage(tinyImage)

        await vm.createPing()

        #expect(vm.didCreatePing)
        #expect(ping.uploadPingImageCalled)
        #expect(ping.createPingWithChatCalled)
    }

    @Test func createPingWithoutImageSkipsUpload() async {
        let auth = authenticatedAuth()
        let ping = MockPingService()
        let location = MockLocationService()
        location.boundaryResult = true
        let vm = makeVM(authService: auth, pingService: ping, locationService: location)
        vm.text = "Ping without photo"
        vm.selectedLocation = clujCoordinate

        await vm.createPing()

        #expect(vm.didCreatePing)
        #expect(ping.uploadPingImageCalled == false)
        #expect(ping.createPingWithChatCalled)
    }

    // MARK: - Rate Limiting

    @Test("Rate limited user cannot create ping")
    func rateLimitedCannotCreatePing() async {
        let mockAuth = MockAuthService()
        mockAuth.currentUser = MockAuthUser(uid: "user1", isEmailVerified: true)
        mockAuth.isEmailVerified = true
        let mockPing = MockPingService()
        let mockChat = MockChatService()
        let mockLocation = MockLocationService()
        mockLocation.boundaryResult = true
        let mockModeration = MockContentModerationService()
        let mockRateLimit = MockRateLimitService()
        mockRateLimit.pingResult = .limited(retryAfter: 300)

        let vm = CreatePingViewModel()
        vm.configure(
            authService: mockAuth,
            pingService: mockPing,
            chatService: mockChat,
            locationService: mockLocation,
            contentModerationService: mockModeration,
            rateLimitService: mockRateLimit
        )
        vm.text = "Test"
        vm.selectedLocation = Constants.Cluj.center

        await vm.createPing()

        #expect(vm.didCreatePing == false)
        #expect(vm.errorMessage != nil)
        #expect(mockPing.createPingWithChatCalled == false)
    }
}
