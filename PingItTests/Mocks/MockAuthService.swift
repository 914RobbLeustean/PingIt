import Observation
@testable import PingIt

@Observable
@MainActor
final class MockAuthService: AuthServicing {
    var currentUser: (any AuthUserRepresentable)?
    var isLoading = false

    var signUpCalled = false
    var signInCalled = false
    var signOutCalled = false
    var errorToThrow: Error?

    func signUp(email: String, password: String, username: String) async throws {
        signUpCalled = true
        if let error = errorToThrow { throw error }
    }

    func signIn(email: String, password: String) async throws {
        signInCalled = true
        if let error = errorToThrow { throw error }
    }

    func signOut() throws {
        signOutCalled = true
        if let error = errorToThrow { throw error }
    }
}
