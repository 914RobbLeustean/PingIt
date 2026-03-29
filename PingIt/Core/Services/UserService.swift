import Foundation
import FirebaseFirestore

@Observable
final class UserService {
    private let db = Firestore.firestore()

    func createUserProfile(_ user: User) async throws {
        guard let userId = user.id else { return }
        do {
            try db.collection(Constants.Firestore.usersCollection)
                .document(userId)
                .setData(from: user)
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
}
