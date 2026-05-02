import Testing
import FirebaseFirestore
@testable import PingIt

@Suite("Privacy Profile Enforcement")
@MainActor
struct PrivacyProfileTests {

    private func makePing(creatorId: String = "creator1") -> Ping {
        var ping = Ping(
            creatorId: creatorId,
            text: "Test ping",
            location: GeoPoint(latitude: 46.77, longitude: 23.62),
            geohash: "",
            expiresAt: Date.now.addingTimeInterval(3600),
            status: .active,
            chatId: "chat-1"
        )
        ping.id = "ping-test-1"
        return ping
    }

    private func makeVM(
        creatorId: String = "creator1",
        viewerUid: String = "viewer1",
        isPrivateProfile: Bool = false
    ) -> PingDetailViewModel {
        let auth = MockAuthService()
        auth.currentUser = MockAuthUser(uid: viewerUid)

        let userService = MockUserService()
        var creator = User(username: "creator", email: "c@test.com", usernameLowercase: "creator")
        creator.id = creatorId
        creator.isPrivateProfile = isPrivateProfile
        creator.profileImageUrl = "https://example.com/photo.jpg"
        userService.userToReturn = creator

        let vm = PingDetailViewModel(ping: makePing(creatorId: creatorId))
        vm.configure(
            authService: auth,
            pingService: MockPingService(),
            chatService: MockChatService(),
            userService: userService
        )
        return vm
    }

    @Test func publicProfileShowsCreatorIdentity() async {
        let vm = makeVM(isPrivateProfile: false)
        await vm.loadCreator()
        #expect(!vm.shouldHideCreatorIdentity)
    }

    @Test func privateProfileHidesIdentityForNonCreator() async {
        let vm = makeVM(creatorId: "creator1", viewerUid: "other-user", isPrivateProfile: true)
        await vm.loadCreator()
        #expect(vm.shouldHideCreatorIdentity)
    }

    @Test func privateProfileShowsIdentityForCreator() async {
        let vm = makeVM(creatorId: "creator1", viewerUid: "creator1", isPrivateProfile: true)
        await vm.loadCreator()
        #expect(!vm.shouldHideCreatorIdentity)
    }

    @Test func hiddenIdentityBeforeCreatorLoads() {
        let vm = makeVM(isPrivateProfile: true)
        #expect(!vm.shouldHideCreatorIdentity)
    }
}
