import Foundation
import FirebaseFirestore

@Observable
final class ChatService: ChatServicing {
    private let db = Firestore.firestore()

    func sendMessage(_ message: ChatMessage) async throws {
        do {
            try db.collection(Constants.Firestore.chatMessagesCollection)
                .addDocument(from: message)
        } catch {
            throw PingItError.firestoreWriteFailed(underlying: error)
        }
    }

    /// Joins chat if not already an active participant. Returns the participant document ID.
    func joinChatIfNeeded(chatId: String, userId: String) async throws -> String {
        let existing = try await db.collection(Constants.Firestore.chatParticipantsCollection)
            .whereField("chatId", isEqualTo: chatId)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()

        if let doc = existing.documents.first {
            let data = doc.data()
            if data["leftAt"] != nil {
                try await doc.reference.updateData(["leftAt": FieldValue.delete()])
            }
            return doc.documentID
        }

        let participant = ChatParticipant(chatId: chatId, userId: userId)
        do {
            let ref = try db.collection(Constants.Firestore.chatParticipantsCollection)
                .addDocument(from: participant)
            return ref.documentID
        } catch {
            throw PingItError.firestoreWriteFailed(underlying: error)
        }
    }

    func leaveChat(participantId: String) async throws {
        do {
            try await db.collection(Constants.Firestore.chatParticipantsCollection)
                .document(participantId)
                .updateData(["leftAt": FieldValue.serverTimestamp()])
        } catch {
            throw PingItError.firestoreWriteFailed(underlying: error)
        }
    }

    func createChat(pingId: String) async throws -> String {
        let chat = Chat(pingId: pingId)
        do {
            let ref = try db.collection(Constants.Firestore.chatsCollection)
                .addDocument(from: chat)
            return ref.documentID
        } catch {
            throw PingItError.firestoreWriteFailed(underlying: error)
        }
    }

    func deleteChat(id: String) async throws {
        do {
            try await db.collection(Constants.Firestore.chatsCollection)
                .document(id)
                .delete()
        } catch {
            throw PingItError.firestoreWriteFailed(underlying: error)
        }
    }

    func observeMessages(
        chatId: String,
        onUpdate: @escaping @Sendable (Result<[ChatMessage], Error>) -> Void
    ) -> ListenerHandle {
        let registration = db.collection(Constants.Firestore.chatMessagesCollection)
            .whereField("chatId", isEqualTo: chatId)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onUpdate(.failure(error))
                    return
                }
                let messages = (snapshot?.documents.compactMap { try? $0.data(as: ChatMessage.self) } ?? [])
                    .sorted { ($0.createdAt ?? .distantFuture) < ($1.createdAt ?? .distantFuture) }
                onUpdate(.success(messages))
            }
        return ListenerHandle(registration)
    }
}
