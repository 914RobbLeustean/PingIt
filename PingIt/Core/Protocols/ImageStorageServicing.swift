import Foundation

protocol ImageStorageServicing: Sendable {
    func uploadProfileImage(data: Data, userId: String) async throws -> String
    func deleteProfileImage(userId: String) async throws
}
