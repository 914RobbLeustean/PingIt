import Foundation

struct UserSearchResult: Identifiable, Equatable, Sendable {
    let userId: String
    let username: String
    let profileImageUrl: String?
    let followerCount: Int

    var id: String { userId }
}

struct FollowResult: Equatable, Sendable {
    let isFollowing: Bool
    let followerCount: Int
}

protocol FollowServicing {
    func searchUsers(query: String) async throws -> [UserSearchResult]
    /// Toggles the current user's follow on the target user.
    func toggleFollow(userId: String) async throws -> FollowResult
    func isFollowing(userId: String, currentUserId: String) async throws -> Bool
    /// Users the given user currently follows.
    func fetchFollowing(currentUserId: String) async throws -> [User]
}
