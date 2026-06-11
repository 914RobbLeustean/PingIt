import Foundation
@testable import PingIt

@MainActor @Observable
final class MockImageStorageService: ImageStorageServicing {
    var uploadedData: Data?
    var uploadCalled = false
    var deleteCalled = false
    var urlToReturn = "https://example.com/profile.jpg"
    var errorToThrow: Error?

    nonisolated func uploadProfileImage(data: Data, userId: String) async throws -> String {
        try await MainActor.run {
            if let error = errorToThrow { throw error }
            uploadCalled = true
            uploadedData = data
            return urlToReturn
        }
    }

    nonisolated func deleteProfileImage(userId: String) async throws {
        try await MainActor.run {
            if let error = errorToThrow { throw error }
            deleteCalled = true
        }
    }
}
