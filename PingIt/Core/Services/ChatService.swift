import Foundation
import FirebaseFirestore

@Observable
final class ChatService {
    private let db = Firestore.firestore()

    func sendMessage(_ message: ChatMessage) async throws {
        do {
            try db.collection(Constants.Firestore.chatMessagesCollection)
                .addDocument(from: message)
        } catch {
            throw PingItError.firestoreWriteFailed(underlying: error)
        }
    }

    func joinChat(chatId: String, userId: String) async throws {
        let participant = ChatParticipant(chatId: chatId, userId: userId)
        do {
            try db.collection(Constants.Firestore.chatParticipantsCollection)
                .addDocument(from: participant)
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
    ) -> ListenerRegistration {
        db.collection(Constants.Firestore.chatMessagesCollection)
            .whereField("chatId", isEqualTo: chatId)
            .order(by: "createdAt")
            .addSnapshotListener { snapshot, error in
                if let error {
                    onUpdate(.failure(error))
                    return
                }
                let messages = snapshot?.documents.compactMap { try? $0.data(as: ChatMessage.self) } ?? []
                onUpdate(.success(messages))
            }
    }
}
