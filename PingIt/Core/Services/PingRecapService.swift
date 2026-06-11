import Foundation
import FirebaseFirestore
import FirebaseStorage

@Observable
final class PingRecapService: PingRecapServicing {
    private let db = Firestore.firestore()

    func observeActiveRecaps(
        onUpdate: @escaping @Sendable (Result<[PingRecap], Error>) -> Void
    ) -> ListenerHandle {
        let registration = db.collection(Constants.Firestore.pingRecapsCollection)
            .whereField("ghostExpiresAt", isGreaterThan: Date.now)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onUpdate(.failure(error))
                    return
                }
                let recaps = snapshot?.documents.compactMap { try? $0.data(as: PingRecap.self) } ?? []
                onUpdate(.success(recaps))
            }
        return ListenerHandle(registration)
    }

    func observePhotos(
        recapId: String,
        onUpdate: @escaping @Sendable (Result<[PingRecapPhoto], Error>) -> Void
    ) -> ListenerHandle {
        let registration = db.collection(Constants.Firestore.pingRecapsCollection)
            .document(recapId)
            .collection(Constants.Firestore.recapPhotosSubcollection)
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onUpdate(.failure(error))
                    return
                }
                let photos = snapshot?.documents.compactMap { try? $0.data(as: PingRecapPhoto.self) } ?? []
                onUpdate(.success(photos))
            }
        return ListenerHandle(registration)
    }

    func submitRecapPhoto(recapId: String, submitterId: String, imageData: Data) async throws {
        // Doc ref first — the Storage file is named after the photo doc id so
        // the moderation trigger can map file path to Firestore doc.
        let photoRef = db.collection(Constants.Firestore.pingRecapsCollection)
            .document(recapId)
            .collection(Constants.Firestore.recapPhotosSubcollection)
            .document()

        let path = "\(Constants.Storage.recapPhotosPath)/\(recapId)/\(photoRef.documentID).jpg"
        let storageRef = Storage.storage().reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        let imageUrl: String
        do {
            _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
            imageUrl = try await storageRef.downloadURL().absoluteString
        } catch {
            throw PingItError.pingImageUploadFailed(underlying: error)
        }

        let photo = PingRecapPhoto(
            pingId: recapId,
            submitterId: submitterId,
            imageUrl: imageUrl
        )

        do {
            // Encode explicitly and use the async setData so the write awaits
            // server acknowledgment — a rules rejection (e.g. submission
            // window closed) must surface to the caller as an error.
            let encoded = try Firestore.Encoder().encode(photo)
            try await photoRef.setData(encoded)
        } catch {
            throw PingItError.firestoreWriteFailed(underlying: error)
        }
    }
}
