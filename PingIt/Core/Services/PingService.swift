import Foundation
import FirebaseFirestore

@Observable
final class PingService: PingServicing {
    private let db = Firestore.firestore()

    func createPing(_ ping: Ping) async throws -> String {
        do {
            let ref = try db.collection(Constants.Firestore.pingsCollection)
                .addDocument(from: ping)
            return ref.documentID
        } catch {
            throw PingItError.firestoreWriteFailed(underlying: error)
        }
    }

    func fetchPing(id: String) async throws -> Ping {
        do {
            return try await db.collection(Constants.Firestore.pingsCollection)
                .document(id)
                .getDocument(as: Ping.self)
        } catch {
            throw PingItError.firestoreReadFailed(underlying: error)
        }
    }

    func deletePing(id: String) async throws {
        do {
            try await db.collection(Constants.Firestore.pingsCollection)
                .document(id)
                .delete()
        } catch {
            throw PingItError.firestoreWriteFailed(underlying: error)
        }
    }

    /// Creates a ping and its associated chat atomically using a batched write.
    /// Rate limiting is deferred to a Cloud Function (Phase 1).
    func createPingWithChat(_ ping: Ping) async throws {
        let pingRef = db.collection(Constants.Firestore.pingsCollection).document()
        let chatRef = db.collection(Constants.Firestore.chatsCollection).document()

        var pingWithChat = ping
        pingWithChat.chatId = chatRef.documentID

        let chat = Chat(pingId: pingRef.documentID)

        let batch = db.batch()
        do {
            try batch.setData(from: pingWithChat, forDocument: pingRef)
            try batch.setData(from: chat, forDocument: chatRef)
            try await batch.commit()
        } catch {
            throw PingItError.firestoreWriteFailed(underlying: error)
        }
    }

    /// Deletes a ping and its associated chat atomically using a batched write.
    func deletePingAndChat(pingId: String, chatId: String?) async throws {
        let batch = db.batch()
        batch.deleteDocument(db.collection(Constants.Firestore.pingsCollection).document(pingId))
        if let chatId {
            batch.deleteDocument(db.collection(Constants.Firestore.chatsCollection).document(chatId))
        }
        do {
            try await batch.commit()
        } catch {
            throw PingItError.firestoreWriteFailed(underlying: error)
        }
    }

    func observeActivePings(
        onUpdate: @escaping @Sendable (Result<[Ping], Error>) -> Void
    ) -> ListenerHandle {
        let registration = db.collection(Constants.Firestore.pingsCollection)
            .whereField("status", isEqualTo: Ping.PingStatus.active.rawValue)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onUpdate(.failure(error))
                    return
                }
                let pings = snapshot?.documents.compactMap { try? $0.data(as: Ping.self) } ?? []
                onUpdate(.success(pings))
            }
        return ListenerHandle(registration)
    }
}
