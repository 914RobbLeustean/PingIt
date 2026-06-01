import Foundation
import FirebaseFirestore

@Observable
final class UserService: UserServicing {
    private let db = Firestore.firestore()

    func createUserProfile(_ user: User) async throws {
        guard let userId = user.id else { return }
        let username = user.usernameLowercase.lowercased()
        let batch = db.batch()
        let userRef = db.collection(Constants.Firestore.usersCollection).document(userId)
        let usernameRef = db.collection(Constants.Firestore.usernamesCollection).document(username)

        do {
            batch.setData([
                "userId": userId,
                "createdAt": FieldValue.serverTimestamp(),
            ], forDocument: usernameRef)
            try batch.setData(from: user, forDocument: userRef)
            try await batch.commit()
        } catch {
            throw PingItError.firestoreWriteFailed(underlying: error)
        }
    }

    func fetchUser(id: String) async throws -> User {
        do {
            return try await db.collection(Constants.Firestore.usersCollection)
                .document(id)
                .getDocument(as: User.self)
        } catch {
            throw PingItError.firestoreReadFailed(underlying: error)
        }
    }

    func updateUser(id: String, data: [String: Any]) async throws {
        do {
            try await db.collection(Constants.Firestore.usersCollection)
                .document(id)
                .updateData(data)
        } catch {
            throw PingItError.firestoreWriteFailed(underlying: error)
        }
    }

    /// Like `updateUser` but uses `setData(merge: true)` so the write
    /// succeeds even if the user document doesn't exist yet. Use for
    /// idempotent state writes (e.g. flipping onboarding flags).
    func mergeUser(id: String, data: [String: Any]) async throws {
        do {
            try await db.collection(Constants.Firestore.usersCollection)
                .document(id)
                .setData(data, merge: true)
        } catch {
            throw PingItError.firestoreWriteFailed(underlying: error)
        }
    }

    /// Returns the existing user doc, or creates a minimal valid one if it's
    /// missing (Auth user exists but Firestore doc was never written — e.g.
    /// signup partially failed). The placeholder username is derived from the
    /// uid so it can never collide with a real reservation.
    func ensureUserProfileExists(uid: String, email: String) async throws -> User {
        let userRef = db.collection(Constants.Firestore.usersCollection).document(uid)

        do {
            let snapshot = try await userRef.getDocument()
            if snapshot.exists {
                return try snapshot.data(as: User.self)
            }
        } catch {
            throw PingItError.firestoreReadFailed(underlying: error)
        }

        // Derive a guaranteed-valid placeholder username from the uid.
        // safeUserCreate requires it to match ^[A-Za-z0-9_]+$ and be 3–20 chars.
        let prefix = uid.lowercased()
            .filter { $0.isLetter || $0.isNumber }
            .prefix(12)
        let placeholderUsername = "user_\(prefix)"

        let backfilled = User(
            username: placeholderUsername,
            email: email,
            usernameLowercase: placeholderUsername
        )

        do {
            let batch = db.batch()
            let usernameRef = db.collection(Constants.Firestore.usernamesCollection)
                .document(placeholderUsername)
            batch.setData([
                "userId": uid,
                "createdAt": FieldValue.serverTimestamp(),
            ], forDocument: usernameRef)
            try batch.setData(from: backfilled, forDocument: userRef)
            try await batch.commit()
        } catch {
            throw PingItError.firestoreWriteFailed(underlying: error)
        }

        return backfilled
    }

    func updateUsername(id: String, currentUsername: String?, newUsername: String) async throws {
        let normalized = newUsername.lowercased()
        let usernameRef = db.collection(Constants.Firestore.usernamesCollection).document(normalized)

        do {
            let usernameDoc = try await usernameRef.getDocument()
            if usernameDoc.exists {
                guard usernameDoc.data()?["userId"] as? String == id else {
                    throw PingItError.usernameAlreadyTaken
                }
            }

            let batch = db.batch()
            if !usernameDoc.exists {
                batch.setData([
                    "userId": id,
                    "createdAt": FieldValue.serverTimestamp(),
                ], forDocument: usernameRef)
            }

            batch.updateData([
                "username": newUsername,
                "usernameLowercase": normalized,
            ], forDocument: db.collection(Constants.Firestore.usersCollection).document(id))

            let oldUsername = currentUsername?.lowercased()
            if let oldUsername, oldUsername != normalized {
                let oldUsernameRef = db.collection(Constants.Firestore.usernamesCollection).document(oldUsername)
                let oldUsernameDoc = try await oldUsernameRef.getDocument()
                if oldUsernameDoc.exists {
                    batch.deleteDocument(oldUsernameRef)
                }
            }

            try await batch.commit()
        } catch let error as PingItError {
            throw error
        } catch {
            throw PingItError.firestoreWriteFailed(underlying: error)
        }
    }

    func isUsernameTaken(_ username: String) async throws -> Bool {
        do {
            let snapshot = try await db.collection(Constants.Firestore.usernamesCollection)
                .document(username.lowercased())
                .getDocument()
            return snapshot.exists
        } catch {
            throw PingItError.firestoreReadFailed(underlying: error)
        }
    }
}
