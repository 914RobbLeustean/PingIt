import Foundation
import Observation
@testable import PingIt

@Observable
@MainActor
final class MockFollowService: FollowServicing {
    var errorToThrow: Error?

    var searchResultsToReturn: [UserSearchResult] = []
    var followingToReturn: [User] = []
    var isFollowingResult = false
    var toggleFollowResult = FollowResult(isFollowing: true, followerCount: 1)

    private(set) var searchUsersCalled = false
    private(set) var lastSearchQuery: String?
    private(set) var toggleFollowCalled = false
    private(set) var lastToggledUserId: String?
    private(set) var fetchFollowingCalled = false

    func searchUsers(query: String) async throws -> [UserSearchResult] {
        searchUsersCalled = true
        lastSearchQuery = query
        if let error = errorToThrow { throw error }
        return searchResultsToReturn
    }

    func toggleFollow(userId: String) async throws -> FollowResult {
        toggleFollowCalled = true
        lastToggledUserId = userId
        if let error = errorToThrow { throw error }
        return toggleFollowResult
    }

    func isFollowing(userId: String, currentUserId: String) async throws -> Bool {
        if let error = errorToThrow { throw error }
        return isFollowingResult
    }

    func fetchFollowing(currentUserId: String) async throws -> [User] {
        fetchFollowingCalled = true
        if let error = errorToThrow { throw error }
        return followingToReturn
    }
}
