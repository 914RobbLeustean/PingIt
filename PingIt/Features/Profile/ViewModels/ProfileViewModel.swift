import Foundation
import PhotosUI
import SwiftUI
import FirebaseStorage

@Observable
final class ProfileViewModel {
    private var authService: (any AuthServicing)?
    private var userService: (any UserServicing)?
    private var isConfigured = false

    private(set) var user: User?
    private(set) var isLoading = false
    private(set) var isSaving = false
    private(set) var isUploadingImage = false
    private(set) var errorMessage: String?
    private(set) var successMessage: String?

    var editedUsername = ""
    var selectedPhotoItem: PhotosPickerItem?

    var hasUnsavedUsernameChanges: Bool {
        guard let user else { return false }
        return editedUsername != user.username
    }

    var isUsernameValid: Bool {
        let trimmed = editedUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return trimmed.count >= Constants.Username.minLength
            && trimmed.count <= Constants.Username.maxLength
            && trimmed.range(of: Constants.Username.allowedCharacterPattern, options: .regularExpression) != nil
    }

    var canSaveUsername: Bool {
        hasUnsavedUsernameChanges && isUsernameValid && !isSaving
    }

    private var currentUserId: String? {
        authService?.currentUser?.uid
    }

    func configure(authService: any AuthServicing, userService: any UserServicing) {
        guard !isConfigured else { return }
        self.authService = authService
        self.userService = userService
        isConfigured = true
    }

    func loadProfile() async {
        guard let currentUserId, let userService else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            user = try await userService.fetchUser(id: currentUserId)
            editedUsername = user?.username ?? ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveUsername() async {
        guard let currentUserId, let userService else { return }

        let trimmed = editedUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count < Constants.Username.minLength {
            errorMessage = PingItError.usernameTooShort.localizedDescription
            return
        }
        if trimmed.count > Constants.Username.maxLength {
            errorMessage = PingItError.usernameTooLong.localizedDescription
            return
        }
        if trimmed.range(of: Constants.Username.allowedCharacterPattern, options: .regularExpression) == nil {
            errorMessage = PingItError.usernameInvalidCharacters.localizedDescription
            return
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            try await userService.updateUsername(
                id: currentUserId,
                currentUsername: user?.usernameLowercase,
                newUsername: trimmed
            )
            user?.username = trimmed
            user?.usernameLowercase = trimmed.lowercased()
            successMessage = "Username updated"
        } catch PingItError.usernameAlreadyTaken {
            errorMessage = PingItError.usernameAlreadyTaken.localizedDescription
        } catch {
            errorMessage = PingItError.profileUpdateFailed(underlying: error).localizedDescription
        }
    }

    func handleSelectedPhoto() async {
        guard let selectedPhotoItem, let currentUserId, let userService else { return }

        isUploadingImage = true
        errorMessage = nil
        defer {
            isUploadingImage = false
            self.selectedPhotoItem = nil
        }

        do {
            guard let imageData = try await selectedPhotoItem.loadTransferable(type: Data.self) else {
                errorMessage = "Could not load the selected image."
                return
            }

            // Compress image
            guard let compressedData = compressImage(imageData) else {
                errorMessage = "Could not process the selected image."
                return
            }

            // Check size
            guard compressedData.count <= Constants.Storage.maxProfileImageSizeBytes else {
                errorMessage = PingItError.profileImageTooLarge.localizedDescription
                return
            }

            // Upload to Firebase Storage
            let downloadURL = try await uploadToStorage(data: compressedData, userId: currentUserId)

            // Save URL to Firestore
            try await userService.updateUser(id: currentUserId, data: ["profileImageUrl": downloadURL])
            user?.profileImageUrl = downloadURL
            successMessage = "Profile picture updated"
        } catch {
            errorMessage = PingItError.profileImageUploadFailed(underlying: error).localizedDescription
        }
    }

    func removeProfilePicture() async {
        guard let currentUserId, let userService, user?.profileImageUrl != nil else { return }

        isUploadingImage = true
        errorMessage = nil
        defer { isUploadingImage = false }

        do {
            // Delete from Storage (best-effort — file may not exist)
            let storageRef = Storage.storage().reference()
                .child(Constants.Storage.profilePicturesPath)
                .child(currentUserId)
                .child("profile.jpg")
            try? await storageRef.delete()

            // Clear URL in Firestore
            try await userService.updateUser(id: currentUserId, data: ["profileImageUrl": ""])
            user?.profileImageUrl = nil
            successMessage = "Profile picture removed"
        } catch {
            errorMessage = PingItError.profileUpdateFailed(underlying: error).localizedDescription
        }
    }

    func handleCameraImage(_ image: UIImage) async {
        guard let currentUserId, let userService else { return }

        isUploadingImage = true
        errorMessage = nil
        defer { isUploadingImage = false }

        do {
            let resized = resizeImage(image, maxDimension: 500)
            guard let compressedData = resized.jpegData(compressionQuality: Constants.Storage.imageCompressionQuality) else {
                errorMessage = "Could not process the captured image."
                return
            }

            guard compressedData.count <= Constants.Storage.maxProfileImageSizeBytes else {
                errorMessage = PingItError.profileImageTooLarge.localizedDescription
                return
            }

            let downloadURL = try await uploadToStorage(data: compressedData, userId: currentUserId)
            try await userService.updateUser(id: currentUserId, data: ["profileImageUrl": downloadURL])
            user?.profileImageUrl = downloadURL
            successMessage = "Profile picture updated"
        } catch {
            errorMessage = PingItError.profileImageUploadFailed(underlying: error).localizedDescription
        }
    }

    // MARK: - Private

    private func compressImage(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let resized = resizeImage(image, maxDimension: 500)
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

    private func uploadToStorage(data: Data, userId: String) async throws -> String {
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
}
