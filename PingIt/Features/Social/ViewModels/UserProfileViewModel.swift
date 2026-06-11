import Foundation

@Observable
@MainActor
final class UserProfileViewModel {
    private var followService: (any FollowServicing)?
    private var userService: (any UserServicing)?
    private var pingService: (any PingServicing)?
    private var authService: (any AuthServicing)?
    private var isConfigured = false

    let userId: String
    private(set) var user: User?
    private(set) var pingCount = 0
    private(set) var totalBoosts = 0
    private(set) var followerCount = 0
    private(set) var isFollowing = false
    private(set) var isLoading = true
    private(set) var isTogglingFollow = false
    private(set) var isCheckingFollowStatus = true
    var errorMessage: String?

    init(userId: String) {
        self.userId = userId
    }

    var isOwnProfile: Bool {
        authService?.currentUser?.uid == userId
    }

    /// A user who went private after being followed shows as anonymous and
    /// can't gain new followers (dormant follow).
    var isPrivate: Bool {
        user?.isPrivateProfile == true
    }

    var canToggleFollow: Bool {
        !isOwnProfile
        && !isTogglingFollow
        && !isCheckingFollowStatus
        && (isFollowing || !isPrivate)
    }

    var memberSinceFormatted: String {
        guard let createdAt = user?.createdAt else { return "—" }
        return createdAt.formatted(date: .long, time: .omitted)
    }

    var avatarInitial: String {
        guard !isPrivate, let username = user?.username, let first = username.first else { return "?" }
        return String(first).uppercased()
    }

    var displayName: String {
        isPrivate ? "anonymous" : (user?.username ?? "...")
    }

    func configure(
        followService: any FollowServicing,
        userService: any UserServicing,
        pingService: any PingServicing,
        authService: any AuthServicing
    ) {
        guard !isConfigured else { return }
        self.followService = followService
        self.userService = userService
        self.pingService = pingService
        self.authService = authService
        isConfigured = true
    }

    func load() async {
        guard let userService, let pingService else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let fetched = try await userService.fetchUser(id: userId)
            user = fetched
            followerCount = fetched.followerCount ?? 0

            let pings = try await pingService.fetchPings(byCreatorId: userId)
            pingCount = pings.count
            totalBoosts = pings.reduce(0) { $0 + $1.boostCount }
        } catch {
            errorMessage = error.localizedDescription
        }

        await checkFollowStatus()
    }

    func checkFollowStatus() async {
        guard let followService,
              let currentUserId = authService?.currentUser?.uid,
              currentUserId != userId else {
            isCheckingFollowStatus = false
            return
        }
        defer { isCheckingFollowStatus = false }
        do {
            isFollowing = try await followService.isFollowing(userId: userId, currentUserId: currentUserId)
        } catch {
            // Default to not following
        }
    }

    func toggleFollow() async {
        guard let followService, canToggleFollow else { return }
        isTogglingFollow = true
        defer { isTogglingFollow = false }

        do {
            let result = try await followService.toggleFollow(userId: userId)
            isFollowing = result.isFollowing
            followerCount = result.followerCount
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
