import Foundation

@Observable
@MainActor
final class SocialViewModel {
    private var followService: (any FollowServicing)?
    private var authService: (any AuthServicing)?
    private var isConfigured = false
    private var searchTask: Task<Void, Never>?

    var searchText = "" {
        didSet { searchTextDidChange() }
    }

    private(set) var results: [UserSearchResult] = []
    private(set) var isSearching = false
    private(set) var following: [User] = []
    private(set) var followingIds: Set<String> = []
    private(set) var isLoadingFollowing = false
    private(set) var togglingUserIds: Set<String> = []
    var errorMessage: String?

    var isShowingSearchResults: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func configure(
        followService: any FollowServicing,
        authService: any AuthServicing
    ) {
        guard !isConfigured else { return }
        self.followService = followService
        self.authService = authService
        isConfigured = true
    }

    func loadFollowing() async {
        guard let followService,
              let currentUserId = authService?.currentUser?.uid else { return }
        isLoadingFollowing = true
        defer { isLoadingFollowing = false }

        do {
            let users = try await followService.fetchFollowing(currentUserId: currentUserId)
            following = users
            followingIds = Set(users.compactMap(\.id))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func isFollowing(_ userId: String) -> Bool {
        followingIds.contains(userId)
    }

    func toggleFollow(userId: String) async {
        guard let followService, !togglingUserIds.contains(userId) else { return }
        togglingUserIds.insert(userId)
        defer { togglingUserIds.remove(userId) }

        do {
            let result = try await followService.toggleFollow(userId: userId)
            if result.isFollowing {
                followingIds.insert(userId)
            } else {
                followingIds.remove(userId)
                following.removeAll { $0.id == userId }
            }
            results = results.map { searchResult in
                guard searchResult.userId == userId else { return searchResult }
                return UserSearchResult(
                    userId: searchResult.userId,
                    username: searchResult.username,
                    profileImageUrl: searchResult.profileImageUrl,
                    followerCount: result.followerCount
                )
            }
            if result.isFollowing {
                await loadFollowing()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func searchTextDidChange() {
        searchTask?.cancel()
        errorMessage = nil

        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            results = []
            isSearching = false
            return
        }

        isSearching = true
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(Constants.Username.uniquenessCheckDebounceMilliseconds))
            guard !Task.isCancelled else { return }
            await performSearch(query: trimmed)
        }
    }

    private func performSearch(query: String) async {
        guard let followService else { return }
        defer { isSearching = false }

        do {
            let found = try await followService.searchUsers(query: query)
            guard !Task.isCancelled else { return }
            results = found
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
            results = []
        }
    }
}
