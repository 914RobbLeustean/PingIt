import Observation
@testable import PingIt

@Observable
@MainActor
final class MockUserService: UserServicing {
    var userToReturn: User?
    var errorToThrow: Error?
    var isUsernameTakenResult = false

    var createUserProfileCalled = false
    var fetchUserCalled = false
    var updateUserCalled = false
    var updateUsernameCalled = false
    var isUsernameTakenCalled = false
    var lastUpdateData: [String: Any]?
    var lastUpdatedUsername: String?
    var lastCheckedUsername: String?

    func createUserProfile(_ user: User) async throws {
        createUserProfileCalled = true
        if let error = errorToThrow { throw error }
    }

    func fetchUser(id: String) async throws -> User {
        fetchUserCalled = true
        if let error = errorToThrow { throw error }
        return userToReturn ?? User(username: "mockuser", email: "mock@test.com", usernameLowercase: "mockuser")
    }

    func updateUser(id: String, data: [String: Any]) async throws {
        updateUserCalled = true
        lastUpdateData = data
        if let error = errorToThrow { throw error }
    }

    func mergeUser(id: String, data: [String: Any]) async throws {
        updateUserCalled = true
        lastUpdateData = data
        if let error = errorToThrow { throw error }
    }

    func updateUsername(id: String, currentUsername: String?, newUsername: String) async throws {
        updateUsernameCalled = true
        lastUpdatedUsername = newUsername
        if let error = errorToThrow { throw error }
    }

    func isUsernameTaken(_ username: String) async throws -> Bool {
        isUsernameTakenCalled = true
        lastCheckedUsername = username
        if let error = errorToThrow { throw error }
        return isUsernameTakenResult
    }
}
