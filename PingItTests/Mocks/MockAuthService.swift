import Observation
@testable import PingIt

@Observable
@MainActor
final class MockAuthService: AuthServicing {
    var currentUser: (any AuthUserRepresentable)?
    var isLoading = false

    var isEmailVerified = false
    var signUpCalled = false
    var signInCalled = false
    var signOutCalled = false
    var sendPasswordResetCalled = false
    var sendPasswordResetEmail: String?
    var sendEmailVerificationCalled = false
    var reloadUserCalled = false
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

    func sendPasswordReset(email: String) async throws {
        sendPasswordResetCalled = true
        sendPasswordResetEmail = email
        if let error = errorToThrow { throw error }
    }

    func sendEmailVerification() async throws {
        sendEmailVerificationCalled = true
        if let error = errorToThrow { throw error }
    }

    func reloadUser() async throws {
        reloadUserCalled = true
        if let error = errorToThrow { throw error }
    }
}
