import Observation
@testable import PingIt

@Observable
@MainActor
final class MockBlockService: BlockServicing {
    var blockedUserIds: Set<String> = []
    var errorToThrow: Error?
    var blockUserCalled = false
    var unblockUserCalled = false
    var fetchBlockedUsersCalled = false
    var startObservingCalled = false
    var stopObservingCalled = false
    var blocksToReturn: [Block] = []
    var lastBlockedUserId: String?
    var lastUnblockedUserId: String?

    func blockUser(_ userId: String) async throws {
        blockUserCalled = true
        lastBlockedUserId = userId
        if let error = errorToThrow { throw error }
        blockedUserIds.insert(userId)
    }

    func unblockUser(_ userId: String) async throws {
        unblockUserCalled = true
        lastUnblockedUserId = userId
        if let error = errorToThrow { throw error }
        blockedUserIds.remove(userId)
    }

    func fetchBlockedUsers() async throws -> [Block] {
        fetchBlockedUsersCalled = true
        if let error = errorToThrow { throw error }
        return blocksToReturn
    }

    func isBlocked(_ userId: String) -> Bool {
        blockedUserIds.contains(userId)
    }

    func startObserving() {
        startObservingCalled = true
    }

    func stopObserving() {
        stopObservingCalled = true
    }
}
