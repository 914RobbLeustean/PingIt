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

    func observeActivePings(onUpdate: @escaping @Sendable ([Ping]) -> Void) -> ListenerRegistration {
        db.collection(Constants.Firestore.pingsCollection)
            .whereField("status", isEqualTo: Ping.PingStatus.active.rawValue)
            .addSnapshotListener { snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                let pings = documents.compactMap { try? $0.data(as: Ping.self) }
                onUpdate(pings)
            }
    }
}
