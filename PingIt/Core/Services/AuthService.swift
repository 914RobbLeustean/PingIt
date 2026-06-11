import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

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
            let normalizedUsername = username.lowercased()
            let db = Firestore.firestore()
            let usernameDoc = try await db
                .collection(Constants.Firestore.usernamesCollection)
                .document(normalizedUsername)
                .getDocument()

            guard !usernameDoc.exists else {
                throw PingItError.usernameAlreadyTaken
            }

            let result = try await Auth.auth().createUser(withEmail: email, password: password)

            // Create Firestore user profile using the Auth UID as the document ID
            let user = User(
                username: username,
                email: email,
                usernameLowercase: normalizedUsername
            )

            do {
                let batch = db.batch()
                batch.setData([
                    "userId": result.user.uid,
                    "createdAt": FieldValue.serverTimestamp(),
                ], forDocument: db.collection(Constants.Firestore.usernamesCollection).document(normalizedUsername))
                try batch.setData(
                    from: user,
                    forDocument: db.collection(Constants.Firestore.usersCollection).document(result.user.uid)
                )
                try await batch.commit()
            } catch {
                try? await result.user.delete()
                throw PingItError.firestoreWriteFailed(underlying: error)
            }

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

    func reauthenticate(password: String) async throws {
        guard let user = Auth.auth().currentUser, let email = user.email else {
            throw PingItError.notAuthenticated
        }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        do {
            try await user.reauthenticate(with: credential)
        } catch {
            throw PingItError.from(authError: error)
        }
    }

    func deleteAccount() async throws {
        try await deleteAccountRecord()
        try? Auth.auth().signOut()
    }

    /// Deletes the user's account record via the Cloud Function without
    /// signing the user out. Lets the UI show a goodbye state before the
    /// auth listener tears the session down. Call `Auth.auth().signOut()`
    /// (or `signOut()`) once the UI has finished its farewell.
    func deleteAccountRecord() async throws {
        guard Auth.auth().currentUser != nil else {
            throw PingItError.notAuthenticated
        }

        do {
            let functions = Functions.functions(region: "europe-west3")
            let _ = try await functions.httpsCallable("deleteAccount").call()
        } catch {
            throw PingItError.accountDeletionFailed(underlying: error)
        }
    }
}
