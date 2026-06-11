import Testing
import Foundation
import FirebaseFirestore
@testable import PingIt

@Suite("UserProfileViewModel")
@MainActor
struct UserProfileViewModelTests {

    private func makeVM(
        userId: String = "user2",
        currentUid: String = "me",
        followService: MockFollowService? = nil,
        userService: MockUserService? = nil,
        pingService: MockPingService? = nil
    ) -> (UserProfileViewModel, MockFollowService) {
        let follow = followService ?? MockFollowService()
        let auth = MockAuthService()
        auth.currentUser = MockAuthUser(uid: currentUid)
        let vm = UserProfileViewModel(userId: userId)
        vm.configure(
            followService: follow,
            userService: userService ?? MockUserService(),
            pingService: pingService ?? MockPingService(),
            authService: auth
        )
        return (vm, follow)
    }

    private func makeUser(
        username: String = "tester",
        isPrivate: Bool = false,
        followerCount: Int? = 5
    ) -> User {
        var user = User(username: username, email: "t@t.com", usernameLowercase: username)
        user.id = "user2"
        user.isPrivateProfile = isPrivate
        user.followerCount = followerCount
        return user
    }

    @Test func loadPopulatesProfileAndStats() async {
        let userService = MockUserService()
        userService.userToReturn = makeUser()
        let (vm, _) = makeVM(userService: userService)

        await vm.load()

        #expect(vm.user?.username == "tester")
        #expect(vm.followerCount == 5)
        #expect(vm.displayName == "tester")
        #expect(vm.isLoading == false)
    }

    @Test func privateProfileShowsAnonymous() async {
        let userService = MockUserService()
        userService.userToReturn = makeUser(isPrivate: true)
        let (vm, _) = makeVM(userService: userService)

        await vm.load()

        #expect(vm.isPrivate)
        #expect(vm.displayName == "anonymous")
        #expect(vm.avatarInitial == "?")
    }

    @Test func cannotFollowPrivateProfileUnlessAlreadyFollowing() async {
        let userService = MockUserService()
        userService.userToReturn = makeUser(isPrivate: true)
        let (vm, follow) = makeVM(userService: userService)
        follow.isFollowingResult = false

        await vm.load()

        #expect(vm.canToggleFollow == false)
    }

    @Test func canUnfollowPrivateProfileWhenAlreadyFollowing() async {
        let userService = MockUserService()
        userService.userToReturn = makeUser(isPrivate: true)
        let (vm, follow) = makeVM(userService: userService)
        follow.isFollowingResult = true

        await vm.load()

        #expect(vm.isFollowing)
        #expect(vm.canToggleFollow)
    }

    @Test func ownProfileCannotFollow() async {
        let userService = MockUserService()
        userService.userToReturn = makeUser()
        let (vm, _) = makeVM(userId: "me", currentUid: "me", userService: userService)

        await vm.load()

        #expect(vm.isOwnProfile)
        #expect(vm.canToggleFollow == false)
    }

    @Test func toggleFollowUpdatesStateAndCount() async {
        let userService = MockUserService()
        userService.userToReturn = makeUser(followerCount: 5)
        let (vm, follow) = makeVM(userService: userService)
        follow.isFollowingResult = false
        await vm.load()

        follow.toggleFollowResult = FollowResult(isFollowing: true, followerCount: 6)
        await vm.toggleFollow()

        #expect(vm.isFollowing)
        #expect(vm.followerCount == 6)
    }

    @Test func missingFollowerCountDefaultsToZero() async {
        let userService = MockUserService()
        userService.userToReturn = makeUser(followerCount: nil)
        let (vm, _) = makeVM(userService: userService)

        await vm.load()

        #expect(vm.followerCount == 0)
    }
}
