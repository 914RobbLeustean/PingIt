import Foundation
import FirebaseAuth
import FirebaseFirestore

@Observable
@MainActor
final class BlockService: BlockServicing {
    private(set) var blockedUserIds: Set<String> = []
    private let db = Firestore.firestore()

    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    func loadBlockedUsers() async throws {
        guard let currentUserId else { return }

        let asBlocker = try await db
            .collection(Constants.Firestore.blocksCollection)
            .whereField("blockerId", isEqualTo: currentUserId)
            .getDocuments()

        let asBlocked = try await db
            .collection(Constants.Firestore.blocksCollection)
            .whereField("blockedUserId", isEqualTo: currentUserId)
            .getDocuments()

        var ids = Set<String>()
        for doc in asBlocker.documents {
            if let block = try? doc.data(as: Block.self) {
                ids.insert(block.blockedUserId)
            }
        }
        for doc in asBlocked.documents {
            if let block = try? doc.data(as: Block.self) {
                ids.insert(block.blockerId)
            }
        }
        blockedUserIds = ids
    }

    func blockUser(_ userId: String) async throws {
        guard let currentUserId else { throw PingItError.notAuthenticated }
        guard userId != currentUserId else { throw PingItError.cannotBlockSelf }

        do {
            let block = Block(blockerId: currentUserId, blockedUserId: userId)
            try db.collection(Constants.Firestore.blocksCollection)
                .addDocument(from: block)

            blockedUserIds.insert(userId)

            try await db.collection(Constants.Firestore.usersCollection)
                .document(currentUserId)
                .updateData([
                    "blockedUsers": FieldValue.arrayUnion([userId])
                ])
        } catch let error as PingItError {
            throw error
        } catch {
            throw PingItError.blockFailed(underlying: error)
        }
    }

    func unblockUser(_ userId: String) async throws {
        guard let currentUserId else { throw PingItError.notAuthenticated }

        do {
            let snapshot = try await db
                .collection(Constants.Firestore.blocksCollection)
                .whereField("blockerId", isEqualTo: currentUserId)
                .whereField("blockedUserId", isEqualTo: userId)
                .getDocuments()

            for doc in snapshot.documents {
                try await doc.reference.delete()
            }

            blockedUserIds.remove(userId)

            try await db.collection(Constants.Firestore.usersCollection)
                .document(currentUserId)
                .updateData([
                    "blockedUsers": FieldValue.arrayRemove([userId])
                ])
        } catch let error as PingItError {
            throw error
        } catch {
            throw PingItError.unblockFailed(underlying: error)
        }
    }

    func fetchBlockedUsers() async throws -> [Block] {
        guard let currentUserId else { return [] }

        let snapshot = try await db
            .collection(Constants.Firestore.blocksCollection)
            .whereField("blockerId", isEqualTo: currentUserId)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Block.self) }
    }

    func isBlocked(_ userId: String) -> Bool {
        blockedUserIds.contains(userId)
    }
}
