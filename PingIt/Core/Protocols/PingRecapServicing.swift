import Foundation

protocol PingRecapServicing {
    func observeActiveRecaps(
        onUpdate: @escaping @Sendable (Result<[PingRecap], Error>) -> Void
    ) -> ListenerHandle

    func observePhotos(
        recapId: String,
        onUpdate: @escaping @Sendable (Result<[PingRecapPhoto], Error>) -> Void
    ) -> ListenerHandle

    func submitRecapPhoto(recapId: String, submitterId: String, imageData: Data) async throws
}
