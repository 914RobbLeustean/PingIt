import Observation
@testable import PingIt

@Observable
@MainActor
final class MockUserService: UserServicing {
    var userToReturn: User?
    var errorToThrow: Error?

    var createUserProfileCalled = false
    var fetchUserCalled = false
    var updateUserCalled = false
    var lastUpdateData: [String: Any]?

    func createUserProfile(_ user: User) async throws {
        createUserProfileCalled = true
        if let error = errorToThrow { throw error }
    }

    func fetchUser(id: String) async throws -> User {
        fetchUserCalled = true
        if let error = errorToThrow { throw error }
        return userToReturn ?? User(username: "mockuser", email: "mock@test.com")
    }

    func updateUser(id: String, data: [String: Any]) async throws {
        updateUserCalled = true
        lastUpdateData = data
        if let error = errorToThrow { throw error }
    }
}
