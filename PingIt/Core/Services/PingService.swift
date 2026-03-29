import Foundation
import FirebaseFirestore

@Observable
final class PingService {
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

    func createPingWithChat(_ ping: Ping, chatService: ChatService) async throws {
        do {
            let pingId = try await createPing(ping)
            let chatId = try await chatService.createChat(pingId: pingId)
            try await db.collection(Constants.Firestore.pingsCollection)
                .document(pingId)
                .updateData(["chatId": chatId])
        } catch {
            throw PingItError.firestoreWriteFailed(underlying: error)
        }
    }

    func observeActivePings(
        onUpdate: @escaping @Sendable (Result<[Ping], Error>) -> Void
    ) -> ListenerRegistration {
        db.collection(Constants.Firestore.pingsCollection)
            .whereField("status", isEqualTo: Ping.PingStatus.active.rawValue)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onUpdate(.failure(error))
                    return
                }
                let pings = snapshot?.documents.compactMap { try? $0.data(as: Ping.self) } ?? []
                onUpdate(.success(pings))
            }
    }
}
