import Foundation
import FirebaseAuth
import FirebaseFirestore

@Observable
final class AuthService: AuthServicing {
    private(set) var currentUser: (any AuthUserRepresentable)?
    private(set) var isLoading = false
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        currentUser = Auth.auth().currentUser
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func signUp(email: String, password: String, username: String) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)

            // Create Firestore user profile using the Auth UID as the document ID
            let user = User(
                username: username,
                email: email,
                usernameLowercase: username.lowercased()
            )
            try Firestore.firestore()
                .collection(Constants.Firestore.usersCollection)
                .document(result.user.uid)
                .setData(from: user)

            try? await result.user.sendEmailVerification()
        } catch let error as PingItError {
            throw error
        } catch {
            throw PingItError.from(authError: error)
        }
    }

    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            throw PingItError.from(authError: error)
        }
    }

    func signOut() throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw PingItError.signOutFailed(underlying: error)
        }
    }

    var isEmailVerified: Bool {
        guard let firebaseUser = Auth.auth().currentUser else { return false }
        return firebaseUser.isEmailVerified
    }

    func sendPasswordReset(email: String) async throws {
        isLoading = true
        defer { isLoading = false }

        // Suppress errors to avoid email enumeration — always show success
        try? await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func sendEmailVerification() async throws {
        guard let user = Auth.auth().currentUser else {
            throw PingItError.notAuthenticated
        }
        do {
            try await user.sendEmailVerification()
        } catch {
            throw PingItError.emailVerificationFailed(underlying: error)
        }
    }

    func reloadUser() async throws {
        guard let user = Auth.auth().currentUser else {
            throw PingItError.notAuthenticated
        }
        do {
            try await user.reload()
            self.currentUser = Auth.auth().currentUser
        } catch {
            throw PingItError.firestoreReadFailed(underlying: error)
        }
    }
}
