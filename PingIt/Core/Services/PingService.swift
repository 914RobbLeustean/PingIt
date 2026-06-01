import Foundation
import FirebaseFirestore
import FirebaseFunctions
import FirebaseStorage

@Observable
final class PingService: PingServicing {
    private let db = Firestore.firestore()
    private let functions = Functions.functions(region: "europe-west3")

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
            _ = try await functions.httpsCallable("deletePing").call(["pingId": id])
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

    func createPingWithChat(_ ping: Ping, pingId: String) async throws {
        let pingRef = db.collection(Constants.Firestore.pingsCollection).document(pingId)
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

    func uploadPingImage(pingId: String, imageData: Data) async throws -> String {
        let path = "\(Constants.Storage.pingImagesPath)/\(pingId)/\(UUID().uuidString).jpg"
        let ref = Storage.storage().reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        do {
            _ = try await ref.putDataAsync(imageData, metadata: metadata)
            let url = try await ref.downloadURL()
            return url.absoluteString
        } catch {
            throw PingItError.pingImageUploadFailed(underlying: error)
        }
    }

    func observePing(
        id: String,
        onUpdate: @escaping @Sendable (Ping?) -> Void
    ) -> ListenerHandle {
        let registration = db.collection(Constants.Firestore.pingsCollection)
            .document(id)
            .addSnapshotListener { snapshot, _ in
                guard let snapshot, snapshot.exists else {
                    onUpdate(nil)
                    return
                }
                onUpdate(try? snapshot.data(as: Ping.self))
            }
        return ListenerHandle(registration)
    }

    func boostPing(pingId: String) async throws -> BoostPingResult {
        do {
            let result = try await functions.httpsCallable("boostPing").call(["pingId": pingId])
            guard
                let data = result.data as? [String: Any],
                let boostCount = Self.intValue(data["boostCount"]),
                let didBoost = Self.boolValue(data["didBoost"])
            else {
                throw PingItError.firestoreReadFailed(underlying: PingItError.documentNotFound)
            }

            return BoostPingResult(boostCount: boostCount, didBoost: didBoost)
        } catch let error as PingItError {
            throw error
        } catch {
            throw PingItError.firestoreWriteFailed(underlying: error)
        }
    }

    func hasUserBoostedPing(pingId: String, userId: String) async throws -> Bool {
        let snapshot = try await db
            .collection(Constants.Firestore.boostsCollection)
            .whereField("pingId", isEqualTo: pingId)
            .whereField("userId", isEqualTo: userId)
            .limit(to: 1)
            .getDocuments()

        return !snapshot.documents.isEmpty
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

    func fetchPings(byCreatorId creatorId: String) async throws -> [Ping] {
        do {
            let snapshot = try await db.collection(Constants.Firestore.pingsCollection)
                .whereField("creatorId", isEqualTo: creatorId)
                .getDocuments()
            return snapshot.documents.compactMap { try? $0.data(as: Ping.self) }
        } catch {
            throw PingItError.firestoreReadFailed(underlying: error)
        }
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let value = value as? Int {
            return value
        }
        if let value = value as? NSNumber {
            return value.intValue
        }
        return nil
    }

    private static func boolValue(_ value: Any?) -> Bool? {
        if let value = value as? Bool {
            return value
        }
        if let value = value as? NSNumber {
            return value.boolValue
        }
        return nil
    }
}
