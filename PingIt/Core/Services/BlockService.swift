import Foundation
import FirebaseAuth
import FirebaseFirestore

@Observable
@MainActor
final class BlockService: BlockServicing {
    private(set) var blockedUserIds: Set<String> = []
    private let db = Firestore.firestore()
    private var blockerListener: ListenerRegistration?
    private var blockedListener: ListenerRegistration?

    /// IDs of users I blocked (from blockerListener)
    private var blockedByMe: Set<String> = []
    /// IDs of users who blocked me (from blockedListener)
    private var blockedMe: Set<String> = []

    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    func startObserving() {
        guard let currentUserId else { return }
        guard blockerListener == nil, blockedListener == nil else { return }

        // Listener 1: blocks where I am the blocker
        blockerListener = db
            .collection(Constants.Firestore.blocksCollection)
            .whereField("blockerId", isEqualTo: currentUserId)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let snapshot else { return }
                Task { @MainActor [self] in
                    self.blockedByMe = Set(
                        snapshot.documents.compactMap { doc in
                            (try? doc.data(as: Block.self))?.blockedUserId
                        }
                    )
                    self.mergeBlockedIds()
                }
            }

        // Listener 2: blocks where I am the blocked user
        blockedListener = db
            .collection(Constants.Firestore.blocksCollection)
            .whereField("blockedUserId", isEqualTo: currentUserId)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let snapshot else { return }
                Task { @MainActor [self] in
                    self.blockedMe = Set(
                        snapshot.documents.compactMap { doc in
                            (try? doc.data(as: Block.self))?.blockerId
                        }
                    )
                    self.mergeBlockedIds()
                }
            }
    }

    func stopObserving() {
        blockerListener?.remove()
        blockerListener = nil
        blockedListener?.remove()
        blockedListener = nil
        blockedByMe = []
        blockedMe = []
        blockedUserIds = []
    }

    private func mergeBlockedIds() {
        blockedUserIds = blockedByMe.union(blockedMe)
    }

    func blockUser(_ userId: String) async throws {
        guard let currentUserId else { throw PingItError.notAuthenticated }
        guard userId != currentUserId else { throw PingItError.cannotBlockSelf }

        // Idempotency: skip write if already blocked
        guard !blockedUserIds.contains(userId) else { return }

        do {
            let block = Block(blockerId: currentUserId, blockedUserId: userId)
            try db.collection(Constants.Firestore.blocksCollection)
                .addDocument(from: block)

            // Optimistic local update — listener will confirm
            blockedByMe.insert(userId)
            mergeBlockedIds()

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

            // Optimistic local update — listener will confirm
            blockedByMe.remove(userId)
            mergeBlockedIds()

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

    isolated deinit {
        blockerListener?.remove()
        blockedListener?.remove()
    }
}
