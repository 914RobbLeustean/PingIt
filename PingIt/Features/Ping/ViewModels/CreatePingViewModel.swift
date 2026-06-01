import Foundation
import CoreLocation
import FirebaseFirestore
import PhotosUI
import SwiftUI

@MainActor @Observable
final class CreatePingViewModel {
    private var authService: (any AuthServicing)?
    private var pingService: (any PingServicing)?
    private var chatService: (any ChatServicing)?
    private var locationService: (any LocationServicing)?
    private var contentModerationService: (any ContentModeratingServicing)?
    private var rateLimitService: (any RateLimitServicing)?
    private var analyticsService: (any AnalyticsServicing)?
    private var isConfigured = false

    var text = ""
    var selectedCategory: PingCategory?
    var selectedExpirationIndex = 1 // Default: 24hr
    var isCustomDuration = false
    var customDurationHours: Double = 2.0
    var selectedLocation: CLLocationCoordinate2D?
    var selectedLocationName: String?
    private(set) var selectedImageData: Data?
    private(set) var isProcessingImage = false
    private(set) var isCreating = false
    private(set) var errorMessage: String?
    private(set) var didCreatePing = false

    var characterCount: Int { text.count }
    var isOverLimit: Bool { text.count > Constants.Ping.maxTextLength }

    var canCreate: Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !isOverLimit && !isCreating && selectedCategory != nil
    }

    var locationDisplayText: String {
        if let name = selectedLocationName {
            return name
        }
        if let location = selectedLocation {
            return "\(location.latitude.formatted(.number.precision(.fractionLength(4)))), \(location.longitude.formatted(.number.precision(.fractionLength(4))))"
        }
        return "Choose location"
    }

    private static let presetLabels = ["6h", "24h", "48h", "Custom"]

    var selectedExpiration: TimeInterval {
        if isCustomDuration {
            return customDurationHours * 3600
        }
        return Constants.Ping.expirationPresets[selectedExpirationIndex]
    }

    var customExpiryDisplayLabel: String {
        let totalMinutes = Int(customDurationHours * 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if minutes == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(minutes)m"
    }

    var customExpiryAbsoluteLabel: String {
        let expiryDate = Date.now.addingTimeInterval(customDurationHours * 3600)
        return expiryDate.formatted(date: .omitted, time: .shortened)
    }

    func expirationLabel(for index: Int) -> String {
        Self.presetLabels[index]
    }

    func configure(
        authService: any AuthServicing,
        pingService: any PingServicing,
        chatService: any ChatServicing,
        locationService: any LocationServicing,
        contentModerationService: any ContentModeratingServicing,
        rateLimitService: any RateLimitServicing,
        analyticsService: (any AnalyticsServicing)? = nil
    ) {
        guard !isConfigured else { return }
        self.authService = authService
        self.pingService = pingService
        self.chatService = chatService
        self.locationService = locationService
        self.contentModerationService = contentModerationService
        self.rateLimitService = rateLimitService
        self.analyticsService = analyticsService
        isConfigured = true
    }

    func handleSelectedPhoto(item: PhotosPickerItem) async {
        isProcessingImage = true
        defer { isProcessingImage = false }

        do {
            guard let imageData = try await item.loadTransferable(type: Data.self) else {
                return
            }
            guard let compressed = compressImage(imageData) else { return }
            guard compressed.count <= Constants.Storage.maxImageSizeBytes else {
                errorMessage = PingItError.pingImageTooLarge.localizedDescription
                return
            }
            selectedImageData = compressed
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func handleCameraImage(_ image: UIImage) {
        let resized = resizeImage(image, maxDimension: Constants.Storage.pingImageMaxDimension)
        guard let data = resized.jpegData(compressionQuality: Constants.Storage.imageCompressionQuality) else { return }
        guard data.count <= Constants.Storage.maxImageSizeBytes else {
            errorMessage = PingItError.pingImageTooLarge.localizedDescription
            return
        }
        selectedImageData = data
        errorMessage = nil
    }

    func removeSelectedImage() {
        selectedImageData = nil
    }

    func createPing() async {
        guard let authService, let pingService, let locationService else { return }

        isCreating = true
        errorMessage = nil
        defer { isCreating = false }

        do {
            guard let currentUser = authService.currentUser else {
                throw PingItError.notAuthenticated
            }

            guard authService.isEmailVerified else {
                throw PingItError.emailNotVerified
            }

            if let rateLimitService {
                let result = rateLimitService.canCreatePing()
                if case .limited(let retryAfter) = result {
                    let minutes = Int(ceil(retryAfter / 60))
                    throw PingItError.rateLimited(retryAfterMinutes: minutes)
                }
            }

            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw PingItError.pingTextEmpty
            }
            guard trimmed.count <= Constants.Ping.maxTextLength else {
                throw PingItError.pingTextTooLong
            }

            if let moderationService = contentModerationService {
                let result = moderationService.check(trimmed)
                if case .blocked(let reason) = result {
                    throw PingItError.contentModerated(reason: reason)
                }
            }

            guard let coordinate = selectedLocation else {
                throw PingItError.locationUnavailable
            }

            guard locationService.isWithinClujBoundary(coordinate) else {
                throw PingItError.locationOutsideBoundary
            }

            let pingId = Firestore.firestore().collection(Constants.Firestore.pingsCollection).document().documentID

            var imageUrl: String?
            if let imageData = selectedImageData {
                imageUrl = try await pingService.uploadPingImage(pingId: pingId, imageData: imageData)
            }

            let ping = Ping(
                creatorId: currentUser.uid,
                text: trimmed,
                category: selectedCategory?.rawValue,
                location: GeoPoint(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                ),
                geohash: "",
                expiresAt: ServerTime.now.addingTimeInterval(selectedExpiration),
                status: .active,
                imageUrl: imageUrl
            )

            try await pingService.createPingWithChat(ping, pingId: pingId)
            didCreatePing = true
            rateLimitService?.recordPingCreation()

            let durationHours = Int(selectedExpiration / 3600)
            analyticsService?.logEvent(AnalyticsService.EventName.pingCreated, parameters: [
                AnalyticsService.ParameterName.durationType: isCustomDuration ? "custom" : "preset",
                AnalyticsService.ParameterName.durationHours: durationHours,
                AnalyticsService.ParameterName.hasImage: imageUrl != nil
            ])
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
}
