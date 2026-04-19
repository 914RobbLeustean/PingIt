import Testing
@testable import PingIt

@Suite("BlockedUsersViewModel Tests")
@MainActor
struct BlockedUsersViewModelTests {
    @Test("Loads blocked users with profiles")
    func loadsBlockedUsers() async {
        let mockBlockService = MockBlockService()
        mockBlockService.blocksToReturn = [
            Block(blockerId: "me", blockedUserId: "user1"),
            Block(blockerId: "me", blockedUserId: "user2")
        ]

        let mockUserService = MockUserService()

        let vm = BlockedUsersViewModel()
        vm.configure(blockService: mockBlockService, userService: mockUserService)

        await vm.loadBlockedUsers()

        #expect(vm.blockedUsers.count == 2)
        #expect(mockBlockService.fetchBlockedUsersCalled == true)
    }

    @Test("Unblock removes user from list")
    func unblockRemovesUser() async {
        let mockBlockService = MockBlockService()
        mockBlockService.blocksToReturn = [
            Block(blockerId: "me", blockedUserId: "user1")
        ]
        let mockUserService = MockUserService()

        let vm = BlockedUsersViewModel()
        vm.configure(blockService: mockBlockService, userService: mockUserService)
        await vm.loadBlockedUsers()

        await vm.unblockUser(userId: "user1")

        #expect(mockBlockService.unblockUserCalled == true)
        #expect(mockBlockService.lastUnblockedUserId == "user1")
    }
}
