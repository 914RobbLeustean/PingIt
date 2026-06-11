import Testing
import Foundation
@testable import PingIt

@Suite("SocialViewModel")
@MainActor
struct SocialViewModelTests {

    private func makeVM(
        followService: MockFollowService? = nil,
        authService: MockAuthService? = nil
    ) -> (SocialViewModel, MockFollowService) {
        let follow = followService ?? MockFollowService()
        let auth = authService ?? {
            let auth = MockAuthService()
            auth.currentUser = MockAuthUser(uid: "me")
            return auth
        }()
        let vm = SocialViewModel()
        vm.configure(followService: follow, authService: auth)
        return (vm, follow)
    }

    private func searchResult(userId: String = "user2", followers: Int = 3) -> UserSearchResult {
        UserSearchResult(userId: userId, username: "tester", profileImageUrl: nil, followerCount: followers)
    }

    // MARK: - Search

    @Test func shortQueryClearsResultsWithoutSearching() async {
        let (vm, follow) = makeVM()
        vm.searchText = "a"
        try? await Task.sleep(for: .milliseconds(700))
        #expect(follow.searchUsersCalled == false)
        #expect(vm.results.isEmpty)
    }

    @Test func searchIsDebouncedAndReturnsResults() async {
        let (vm, follow) = makeVM()
        follow.searchResultsToReturn = [searchResult()]

        vm.searchText = "te"
        vm.searchText = "tes"
        vm.searchText = "test"
        try? await Task.sleep(for: .milliseconds(900))

        #expect(follow.searchUsersCalled)
        #expect(follow.lastSearchQuery == "test")
        #expect(vm.results.count == 1)
        #expect(vm.isSearching == false)
    }

    @Test func searchErrorSurfacesMessage() async {
        let (vm, follow) = makeVM()
        follow.errorToThrow = PingItError.firestoreReadFailed(underlying: URLError(.notConnectedToInternet))

        vm.searchText = "test"
        try? await Task.sleep(for: .milliseconds(900))

        #expect(vm.errorMessage != nil)
        #expect(vm.results.isEmpty)
    }

    // MARK: - Following

    @Test func loadFollowingPopulatesUsersAndIds() async {
        let (vm, follow) = makeVM()
        var followed = User(username: "friend", email: "f@t.com", usernameLowercase: "friend")
        followed.id = "user2"
        follow.followingToReturn = [followed]

        await vm.loadFollowing()

        #expect(vm.following.count == 1)
        #expect(vm.isFollowing("user2"))
        #expect(vm.isFollowing("stranger") == false)
    }

    // MARK: - Toggle follow

    @Test func toggleFollowAddsToFollowingIds() async {
        let (vm, follow) = makeVM()
        follow.toggleFollowResult = FollowResult(isFollowing: true, followerCount: 4)
        follow.searchResultsToReturn = []

        await vm.toggleFollow(userId: "user2")

        #expect(follow.lastToggledUserId == "user2")
        #expect(vm.isFollowing("user2"))
    }

    @Test func unfollowRemovesFromFollowingList() async {
        let (vm, follow) = makeVM()
        var followed = User(username: "friend", email: "f@t.com", usernameLowercase: "friend")
        followed.id = "user2"
        follow.followingToReturn = [followed]
        await vm.loadFollowing()

        follow.toggleFollowResult = FollowResult(isFollowing: false, followerCount: 0)
        await vm.toggleFollow(userId: "user2")

        #expect(vm.isFollowing("user2") == false)
        #expect(vm.following.isEmpty)
    }

    @Test func toggleFollowUpdatesSearchResultCount() async {
        let (vm, follow) = makeVM()
        follow.searchResultsToReturn = [searchResult(userId: "user2", followers: 3)]
        vm.searchText = "test"
        try? await Task.sleep(for: .milliseconds(900))

        follow.toggleFollowResult = FollowResult(isFollowing: true, followerCount: 4)
        await vm.toggleFollow(userId: "user2")

        #expect(vm.results.first?.followerCount == 4)
    }

    // MARK: - Block filtering

    @Test func applyBlockFilterRemovesBlockedFromResultsAndFollowing() async {
        let (vm, follow) = makeVM()
        var friend = User(username: "friend", email: "f@t.com", usernameLowercase: "friend")
        friend.id = "user2"
        var other = User(username: "other", email: "o@t.com", usernameLowercase: "other")
        other.id = "user3"
        follow.followingToReturn = [friend, other]
        await vm.loadFollowing()
        follow.searchResultsToReturn = [searchResult(userId: "user2"), searchResult(userId: "user3")]
        vm.searchText = "test"
        try? await Task.sleep(for: .milliseconds(900))

        vm.applyBlockFilter(blockedIds: ["user2"])

        #expect(vm.results.map(\.userId) == ["user3"])
        #expect(vm.following.map(\.id) == ["user3"])
        #expect(!vm.followingIds.contains("user2"))
        #expect(vm.isFollowing("user3"))
    }

    @Test func searchResultsLandingAfterBlockAreFiltered() async {
        let (vm, follow) = makeVM()
        vm.applyBlockFilter(blockedIds: ["user2"])
        follow.searchResultsToReturn = [searchResult(userId: "user2"), searchResult(userId: "user3")]

        vm.searchText = "test"
        try? await Task.sleep(for: .milliseconds(900))

        #expect(vm.results.map(\.userId) == ["user3"])
    }

    @Test func followingLoadedAfterBlockIsFiltered() async {
        let (vm, follow) = makeVM()
        vm.applyBlockFilter(blockedIds: ["user2"])
        var blocked = User(username: "friend", email: "f@t.com", usernameLowercase: "friend")
        blocked.id = "user2"
        follow.followingToReturn = [blocked]

        await vm.loadFollowing()

        #expect(vm.following.isEmpty)
        #expect(vm.followingIds.isEmpty)
    }
}
