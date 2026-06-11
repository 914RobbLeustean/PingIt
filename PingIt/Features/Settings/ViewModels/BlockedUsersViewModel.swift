import Foundation

@Observable
@MainActor
final class BlockedUsersViewModel {
    private var blockService: (any BlockServicing)?
    private var userService: (any UserServicing)?
    private var isConfigured = false

    private(set) var blockedUsers: [(block: Block, user: User?)] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    func configure(blockService: any BlockServicing, userService: any UserServicing) {
        guard !isConfigured else { return }
        self.blockService = blockService
        self.userService = userService
        isConfigured = true
    }

    func loadBlockedUsers() async {
        guard let blockService, let userService else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let blocks = try await blockService.fetchBlockedUsers()
            var results: [(block: Block, user: User?)] = []
            for block in blocks {
                let user = try? await userService.fetchUser(id: block.blockedUserId)
                results.append((block: block, user: user))
            }
            blockedUsers = results
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func unblockUser(userId: String) async {
        guard let blockService else { return }

        do {
            try await blockService.unblockUser(userId)
            blockedUsers.removeAll { $0.block.blockedUserId == userId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
