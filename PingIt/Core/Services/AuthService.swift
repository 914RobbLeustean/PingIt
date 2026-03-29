import Foundation
import FirebaseAuth
import FirebaseFirestore

@Observable
final class AuthService {
    private(set) var currentUser: FirebaseAuth.User?
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
                email: email
            )
            try Firestore.firestore()
                .collection(Constants.Firestore.usersCollection)
                .document(result.user.uid)
                .setData(from: user)
        } catch {
            throw PingItError.signUpFailed(underlying: error)
        }
    }

    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            throw PingItError.signInFailed(underlying: error)
        }
    }

    func signOut() throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw PingItError.signOutFailed(underlying: error)
        }
    }
}
