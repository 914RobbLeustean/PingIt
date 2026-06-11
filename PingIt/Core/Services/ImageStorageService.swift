import Foundation
import FirebaseStorage

@MainActor @Observable
final class ImageStorageService: ImageStorageServicing {

    nonisolated func uploadProfileImage(data: Data, userId: String) async throws -> String {
        let storageRef = Storage.storage().reference()
            .child(Constants.Storage.profilePicturesPath)
            .child(userId)
            .child("profile.jpg")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await storageRef.putDataAsync(data, metadata: metadata)
        let url = try await storageRef.downloadURL()
        return url.absoluteString
    }

    nonisolated func deleteProfileImage(userId: String) async throws {
        let storageRef = Storage.storage().reference()
            .child(Constants.Storage.profilePicturesPath)
            .child(userId)
            .child("profile.jpg")
        try await storageRef.delete()
    }
}
