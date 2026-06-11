import Foundation
import FirebaseFirestore
import FirebaseFunctions

@Observable
final class FollowService: FollowServicing {
    private let db = Firestore.firestore()
    private let functions = Functions.functions(region: "europe-west3")

    func searchUsers(query: String) async throws -> [UserSearchResult] {
        do {
            let result = try await functions.httpsCallable("searchUsers").call(["query": query])
            guard
                let data = result.data as? [String: Any],
                let rawResults = data["results"] as? [[String: Any]]
            else {
                return []
            }

            return rawResults.compactMap { raw in
                guard
                    let userId = raw["userId"] as? String,
                    let username = raw["username"] as? String
                else { return nil }
                return UserSearchResult(
                    userId: userId,
                    username: username,
                    profileImageUrl: raw["profileImageUrl"] as? String,
                    followerCount: (raw["followerCount"] as? NSNumber)?.intValue ?? 0
                )
            }
        } catch {
            throw PingItError.firestoreReadFailed(underlying: error)
        }
    }

    func toggleFollow(userId: String) async throws -> FollowResult {
        do {
            let result = try await functions.httpsCallable("toggleFollow").call(["targetUserId": userId])
            guard
                let data = result.data as? [String: Any],
                let isFollowing = (data["isFollowing"] as? NSNumber)?.boolValue,
                let followerCount = (data["followerCount"] as? NSNumber)?.intValue
            else {
                throw PingItError.firestoreReadFailed(underlying: PingItError.documentNotFound)
            }
            return FollowResult(isFollowing: isFollowing, followerCount: followerCount)
        } catch let error as PingItError {
            throw error
        } catch {
            throw PingItError.firestoreWriteFailed(underlying: error)
        }
    }

    func isFollowing(userId: String, currentUserId: String) async throws -> Bool {
        let document = try await db
            .collection(Constants.Firestore.followsCollection)
            .document("\(currentUserId)_\(userId)")
            .getDocument()
        return document.exists
    }

    func fetchFollowing(currentUserId: String) async throws -> [User] {
        do {
            let snapshot = try await db
                .collection(Constants.Firestore.followsCollection)
                .whereField("followerId", isEqualTo: currentUserId)
                .getDocuments()

            let followedIds = snapshot.documents.compactMap { $0.data()["followedId"] as? String }

            var users: [User] = []
            for followedId in followedIds {
                if let user = try? await db
                    .collection(Constants.Firestore.usersCollection)
                    .document(followedId)
                    .getDocument(as: User.self) {
                    users.append(user)
                }
            }
            return users.sorted { $0.username.lowercased() < $1.username.lowercased() }
        } catch {
            throw PingItError.firestoreReadFailed(underlying: error)
        }
    }
}
