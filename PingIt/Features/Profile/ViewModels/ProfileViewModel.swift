import Foundation
import PhotosUI
import SwiftUI

@MainActor @Observable
final class ProfileViewModel {
    private var authService: (any AuthServicing)?
    private var userService: (any UserServicing)?
    private var imageStorageService: (any ImageStorageServicing)?
    private var pingService: (any PingServicing)?
    private var userListener: ListenerHandle?
    private var isConfigured = false

    private(set) var user: User?
    private(set) var isLoading = false
    private(set) var isSaving = false
    private(set) var isUploadingImage = false
    private(set) var errorMessage: String?
    private(set) var successMessage: String?
    private var successDismissTask: Task<Void, Never>?
    private(set) var pingCount = 0
    private(set) var totalBoosts = 0

    var isEditingUsername = false
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

    var memberAge: String {
        guard let createdAt = user?.createdAt else { return "—" }
        let interval = Date.now.timeIntervalSince(createdAt)
        let days = Int(interval / 86400)
        if days < 1 { return "today" }
        if days < 30 { return "\(days)d" }
        let months = days / 30
        if months < 12 { return "\(months)mo" }
        let years = months / 12
        return "\(years)y"
    }

    var memberSinceFormatted: String {
        guard let createdAt = user?.createdAt else { return "—" }
        return createdAt.formatted(date: .long, time: .omitted)
    }

    var followerCount: Int {
        user?.followerCount ?? 0
    }

    var avatarInitial: String {
        guard let username = user?.username, let first = username.first else { return "?" }
        return String(first).uppercased()
    }

    private var currentUserId: String? {
        authService?.currentUser?.uid
    }

    func configure(
        authService: any AuthServicing,
        userService: any UserServicing,
        imageStorageService: any ImageStorageServicing,
        pingService: any PingServicing
    ) {
        guard !isConfigured else { return }
        self.authService = authService
        self.userService = userService
        self.imageStorageService = imageStorageService
        self.pingService = pingService
        isConfigured = true
    }

    func loadProfile() async {
        guard let currentUserId, let userService, let pingService else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            user = try await userService.fetchUser(id: currentUserId)
            editedUsername = user?.username ?? ""

            let pings = try await pingService.fetchPings(byCreatorId: currentUserId)
            pingCount = pings.count
            totalBoosts = pings.reduce(0) { $0 + $1.boostCount }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Live updates for the user document so counters (followers) tick in
    /// real time while the profile is on screen. Username edits in progress
    /// are untouched — only `user` is replaced.
    func startObservingUser() {
        guard let currentUserId, let userService, userListener == nil else { return }
        userListener = userService.observeUser(id: currentUserId) { [weak self] updatedUser in
            guard let self else { return }
            Task { @MainActor [self] in
                guard let updatedUser else { return }
                self.user = updatedUser
            }
        }
    }

    func stopObservingUser() {
        userListener?.remove()
        userListener = nil
    }

    func beginEditingUsername() {
        editedUsername = user?.username ?? ""
        isEditingUsername = true
    }

    func cancelEditingUsername() {
        editedUsername = user?.username ?? ""
        isEditingUsername = false
        errorMessage = nil
        successMessage = nil
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
            isEditingUsername = false
            showSuccess("Username updated")
        } catch PingItError.usernameAlreadyTaken {
            errorMessage = PingItError.usernameAlreadyTaken.localizedDescription
        } catch {
            errorMessage = PingItError.profileUpdateFailed(underlying: error).localizedDescription
        }
    }

    func handleSelectedPhoto() async {
        guard let selectedPhotoItem, let currentUserId, let userService, let imageStorageService else { return }

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

            guard let compressedData = compressImage(imageData) else {
                errorMessage = "Could not process the selected image."
                return
            }

            guard compressedData.count <= Constants.Storage.maxImageSizeBytes else {
                errorMessage = PingItError.profileImageTooLarge.localizedDescription
                return
            }

            let downloadURL = try await imageStorageService.uploadProfileImage(data: compressedData, userId: currentUserId)
            try await userService.updateUser(id: currentUserId, data: ["profileImageUrl": downloadURL])
            user?.profileImageUrl = downloadURL
            showSuccess("Profile picture updated")
        } catch {
            errorMessage = PingItError.profileImageUploadFailed(underlying: error).localizedDescription
        }
    }

    func removeProfilePicture() async {
        guard let currentUserId, let userService, let imageStorageService, user?.profileImageUrl != nil else { return }

        isUploadingImage = true
        errorMessage = nil
        defer { isUploadingImage = false }

        do {
            try? await imageStorageService.deleteProfileImage(userId: currentUserId)
            try await userService.updateUser(id: currentUserId, data: ["profileImageUrl": ""])
            user?.profileImageUrl = nil
            showSuccess("Profile picture removed")
        } catch {
            errorMessage = PingItError.profileUpdateFailed(underlying: error).localizedDescription
        }
    }

    func handleCameraImage(_ image: UIImage) async {
        guard let currentUserId, let userService, let imageStorageService else { return }

        isUploadingImage = true
        errorMessage = nil
        defer { isUploadingImage = false }

        do {
            let resized = resizeImage(image, maxDimension: 500)
            guard let compressedData = resized.jpegData(compressionQuality: Constants.Storage.imageCompressionQuality) else {
                errorMessage = "Could not process the captured image."
                return
            }

            guard compressedData.count <= Constants.Storage.maxImageSizeBytes else {
                errorMessage = PingItError.profileImageTooLarge.localizedDescription
                return
            }

            let downloadURL = try await imageStorageService.uploadProfileImage(data: compressedData, userId: currentUserId)
            try await userService.updateUser(id: currentUserId, data: ["profileImageUrl": downloadURL])
            user?.profileImageUrl = downloadURL
            showSuccess("Profile picture updated")
        } catch {
            errorMessage = PingItError.profileImageUploadFailed(underlying: error).localizedDescription
        }
    }

    // MARK: - Private

    private func showSuccess(_ message: String) {
        successDismissTask?.cancel()
        successMessage = message
        successDismissTask = Task {
            try? await Task.sleep(for: .seconds(3.5))
            guard !Task.isCancelled else { return }
            successMessage = nil
        }
    }

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

    isolated deinit {
        userListener?.remove()
    }
}
