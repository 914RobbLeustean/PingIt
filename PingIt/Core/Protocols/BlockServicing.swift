import Foundation

protocol BlockServicing {
    var blockedUserIds: Set<String> { get }
    func blockUser(_ userId: String) async throws
    func unblockUser(_ userId: String) async throws
    func fetchBlockedUsers() async throws -> [Block]
    func isBlocked(_ userId: String) -> Bool
    func startObserving()
    func stopObserving()
}
