import Testing
import FirebaseFirestore
@testable import PingIt

@Suite("PingDetailViewModel")
@MainActor
struct PingDetailViewModelTests {

    // MARK: - Helpers

    private func makePing(creatorId: String = "creator1", chatId: String? = "chat-1") -> Ping {
        var ping = Ping(
            creatorId: creatorId,
            text: "Test ping",
            location: GeoPoint(latitude: 46.77, longitude: 23.62),
            geohash: "",
            expiresAt: Date.now.addingTimeInterval(3600),
            status: .active,
            chatId: chatId
        )
        // @DocumentID is set by Firestore; set manually in tests so ping.id is non-nil
        ping.id = "ping-test-1"
        return ping
    }

    private func makeVM(
        ping: Ping? = nil,
        authService: MockAuthService = MockAuthService(),
        pingService: MockPingService = MockPingService(),
        chatService: MockChatService = MockChatService(),
        userService: MockUserService = MockUserService()
    ) -> PingDetailViewModel {
        let vm = PingDetailViewModel(ping: ping ?? makePing())
        vm.configure(
            authService: authService,
            pingService: pingService,
            chatService: chatService,
            userService: userService
        )
        return vm
    }

    private func authenticatedAuth(uid: String = "creator1") -> MockAuthService {
        let auth = MockAuthService()
        auth.currentUser = MockAuthUser(uid: uid)
        return auth
    }

    // MARK: - isCreator

    @Test func isCreatorTrueWhenUidMatchesCreatorId() {
        let auth = authenticatedAuth(uid: "creator1")
        let vm = makeVM(ping: makePing(creatorId: "creator1"), authService: auth)
        #expect(vm.isCreator)
    }

    @Test func isCreatorFalseWhenUidDiffers() {
        let auth = authenticatedAuth(uid: "other-user")
        let vm = makeVM(ping: makePing(creatorId: "creator1"), authService: auth)
        #expect(vm.isCreator == false)
    }

    @Test func isCreatorFalseWhenNotAuthenticated() {
        let auth = MockAuthService()
        auth.currentUser = nil
        let vm = makeVM(ping: makePing(creatorId: "creator1"), authService: auth)
        #expect(vm.isCreator == false)
    }

    // MARK: - loadCreator

    @Test func loadCreatorFetchesUser() async {
        let user = MockUserService()
        user.userToReturn = User(username: "testuser", email: "test@test.com", usernameLowercase: "testuser")
        let vm = makeVM(userService: user)

        await vm.loadCreator()

        #expect(user.fetchUserCalled)
        #expect(vm.creator?.username == "testuser")
        #expect(vm.errorMessage == nil)
    }

    @Test func loadCreatorSetsErrorOnFailure() async {
        let user = MockUserService()
        user.errorToThrow = PingItError.firestoreReadFailed(underlying: URLError(.notConnectedToInternet))
        let vm = makeVM(userService: user)

        await vm.loadCreator()

        #expect(vm.creator == nil)
        #expect(vm.errorMessage != nil)
    }

    // MARK: - deletePing

    @Test func deletePingSetsDidDeletePing() async {
        let ping = MockPingService()
        let vm = makeVM(pingService: ping)

        await vm.deletePing()

        #expect(vm.didDeletePing)
        #expect(ping.deletePingAndChatCalled)
        #expect(vm.errorMessage == nil)
    }

    @Test func deletePingSetsErrorOnFailure() async {
        let ping = MockPingService()
        ping.errorToThrow = PingItError.firestoreWriteFailed(underlying: URLError(.notConnectedToInternet))
        let vm = makeVM(pingService: ping)

        await vm.deletePing()

        #expect(vm.didDeletePing == false)
        #expect(vm.errorMessage != nil)
    }

    // MARK: - Boost

    @Test("Boost ping succeeds and increments local count")
    func boostPingSucceeds() async {
        let mockPing = MockPingService()
        mockPing.hasUserBoostedPingResult = false
        let auth = authenticatedAuth(uid: "other-user")
        let vm = makeVM(
            ping: makePing(creatorId: "creator1"),
            authService: auth,
            pingService: mockPing
        )

        await vm.checkBoostStatus()
        #expect(vm.hasUserBoosted == false)
        #expect(vm.canBoost)

        let countBefore = vm.ping.boostCount
        await vm.boostPing()
        #expect(mockPing.boostPingCalled)
        #expect(vm.hasUserBoosted)
        #expect(vm.ping.boostCount == countBefore + 1)
    }

    @Test("Cannot boost own ping")
    func cannotBoostOwnPing() async {
        let auth = authenticatedAuth(uid: "creator1")
        let vm = makeVM(
            ping: makePing(creatorId: "creator1"),
            authService: auth
        )

        await vm.checkBoostStatus()
        #expect(vm.canBoost == false)
    }

    @Test("Boost button disabled while checking boost status")
    func cannotBoostWhileCheckingStatus() {
        let auth = authenticatedAuth(uid: "other-user")
        let vm = makeVM(
            ping: makePing(creatorId: "creator1"),
            authService: auth
        )

        #expect(vm.isCheckingBoostStatus)
        #expect(vm.canBoost == false)
    }

    @Test("Boost button enabled after check completes for non-boosted user")
    func canBoostAfterCheckCompletes() async {
        let mockPing = MockPingService()
        mockPing.hasUserBoostedPingResult = false
        let auth = authenticatedAuth(uid: "other-user")
        let vm = makeVM(
            ping: makePing(creatorId: "creator1"),
            authService: auth,
            pingService: mockPing
        )

        await vm.checkBoostStatus()
        #expect(vm.isCheckingBoostStatus == false)
        #expect(vm.canBoost)
    }

    @Test("Boost button stays disabled after check completes for already-boosted user")
    func cannotBoostAfterCheckConfirmsBoosted() async {
        let mockPing = MockPingService()
        mockPing.hasUserBoostedPingResult = true
        let auth = authenticatedAuth(uid: "other-user")
        let vm = makeVM(
            ping: makePing(creatorId: "creator1"),
            authService: auth,
            pingService: mockPing
        )

        await vm.checkBoostStatus()
        #expect(vm.isCheckingBoostStatus == false)
        #expect(vm.hasUserBoosted)
        #expect(vm.canBoost == false)
    }
}
