import Foundation
import SwiftUI
import PhotosUI

@Observable
@MainActor
final class RecapStoryViewModel {
    private var recapService: (any PingRecapServicing)?
    private var authService: (any AuthServicing)?
    private var blockService: (any BlockServicing)?
    private var photosListener: ListenerHandle?
    private var isConfigured = false

    let recap: PingRecap
    private(set) var photos: [PingRecapPhoto] = []
    private(set) var isLoadingPhotos = true
    private(set) var isUploading = false
    var errorMessage: String?

    init(recap: PingRecap) {
        self.recap = recap
    }

    var visiblePhotos: [PingRecapPhoto] {
        // Reading blockedUserIds (via isBlocked) inside this computed
        // property lets SwiftUI's observation re-render the sheet the
        // moment a block lands — photos from blocked users vanish live.
        photos.filter {
            !$0.isModerated && !(blockService?.isBlocked($0.submitterId) ?? false)
        }
    }

    var canSubmitPhoto: Bool {
        guard let userId = authService?.currentUser?.uid else { return false }
        guard recap.canSubmitPhotos(userId: userId, now: ServerTime.now) else { return false }
        let ownPhotoCount = photos.filter { $0.submitterId == userId }.count
        return ownPhotoCount < Constants.Recap.maxPhotosPerUser
    }

    func configure(
        recapService: any PingRecapServicing,
        authService: any AuthServicing,
        blockService: (any BlockServicing)? = nil
    ) {
        guard !isConfigured else { return }
        self.recapService = recapService
        self.authService = authService
        self.blockService = blockService
        isConfigured = true
    }

    func startObservingPhotos() {
        guard let recapService, let recapId = recap.id, photosListener == nil else { return }

        photosListener = recapService.observePhotos(recapId: recapId) { [weak self] result in
            guard let self else { return }
            Task { @MainActor [self] in
                if case .success(let photos) = result {
                    self.photos = photos
                }
                self.isLoadingPhotos = false
            }
        }
    }

    func stopObservingPhotos() {
        photosListener?.remove()
        photosListener = nil
    }

    func handleSelectedPhoto(item: PhotosPickerItem) async {
        guard let recapService,
              let recapId = recap.id,
              let userId = authService?.currentUser?.uid else { return }

        isUploading = true
        errorMessage = nil
        defer { isUploading = false }

        do {
            guard let rawData = try await item.loadTransferable(type: Data.self),
                  let compressed = compressImage(rawData) else {
                errorMessage = "Couldn't read that photo. Try a different one."
                return
            }
            guard compressed.count <= Constants.Storage.maxImageSizeBytes else {
                errorMessage = PingItError.pingImageTooLarge.localizedDescription
                return
            }
            try await recapService.submitRecapPhoto(
                recapId: recapId,
                submitterId: userId,
                imageData: compressed
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func compressImage(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let resized = resizeImage(image, maxDimension: Constants.Storage.pingImageMaxDimension)
        return resized.jpegData(compressionQuality: Constants.Storage.imageCompressionQuality)
    }

    private func resizeImage(_ image: UIImage, maxDimension: Double) -> UIImage {
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else { return image }

        let scale = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    isolated deinit {
        photosListener?.remove()
    }
}
