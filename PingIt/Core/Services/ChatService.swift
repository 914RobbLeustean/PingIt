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

    func observeMessages(chatId: String, onUpdate: @escaping @Sendable ([ChatMessage]) -> Void) -> ListenerRegistration {
        db.collection(Constants.Firestore.chatMessagesCollection)
            .whereField("chatId", isEqualTo: chatId)
            .order(by: "createdAt")
            .addSnapshotListener { snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                let messages = documents.compactMap { try? $0.data(as: ChatMessage.self) }
                onUpdate(messages)
            }
    }
}
