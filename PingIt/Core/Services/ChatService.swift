import Foundation
import FirebaseFirestore
import FirebaseFunctions

@Observable
final class ChatService: ChatServicing {
    private let db = Firestore.firestore()
    private let functions = Functions.functions(region: "europe-west3")

    func sendMessage(_ message: ChatMessage) async throws {
        do {
            try db.collection(Constants.Firestore.chatMessagesCollection)
                .addDocument(from: message)
        } catch {
            throw PingItError.firestoreWriteFailed(underlying: error)
        }
    }

    /// Joins chat through the server-authoritative participant counter.
    func joinChatIfNeeded(chatId: String) async throws -> ChatJoinResult {
        do {
            let result = try await functions.httpsCallable("joinChat").call(["chatId": chatId])
            guard
                let data = result.data as? [String: Any],
                let participantId = data["participantId"] as? String,
                let participantCount = Self.intValue(data["participantCount"])
            else {
                throw PingItError.firestoreReadFailed(underlying: PingItError.documentNotFound)
            }
            return ChatJoinResult(participantId: participantId, participantCount: participantCount)
        } catch let error as PingItError {
            throw error
        } catch {
            throw PingItError.firestoreWriteFailed(underlying: error)
        }
    }

    func leaveChat(chatId: String) async throws {
        do {
            _ = try await functions.httpsCallable("leaveChat").call(["chatId": chatId])
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

    func fetchMessages(chatId: String, before: Date?, limit: Int) async throws -> [ChatMessage] {
        var query = db.collection(Constants.Firestore.chatMessagesCollection)
            .whereField("chatId", isEqualTo: chatId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)

        if let before {
            query = query.whereField("createdAt", isLessThan: Timestamp(date: before))
        }

        let snapshot = try await query.getDocuments()
        return snapshot.documents
            .compactMap { try? $0.data(as: ChatMessage.self) }
            .sorted { ($0.createdAt ?? .distantFuture) < ($1.createdAt ?? .distantFuture) }
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

    func observeNewMessages(
        chatId: String,
        after: Date,
        onUpdate: @escaping @Sendable (Result<[ChatMessage], Error>) -> Void
    ) -> ListenerHandle {
        let registration = db.collection(Constants.Firestore.chatMessagesCollection)
            .whereField("chatId", isEqualTo: chatId)
            .whereField("createdAt", isGreaterThan: Timestamp(date: after))
            .order(by: "createdAt")
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

    private static func intValue(_ value: Any?) -> Int? {
        if let value = value as? Int {
            return value
        }
        if let value = value as? NSNumber {
            return value.intValue
        }
        return nil
    }
}
