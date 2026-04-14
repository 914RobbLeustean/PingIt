import Foundation
import CoreLocation
import FirebaseFirestore

@Observable
final class CreatePingViewModel {
    private var authService: (any AuthServicing)?
    private var pingService: (any PingServicing)?
    private var chatService: (any ChatServicing)?
    private var locationService: (any LocationServicing)?
    private var contentModerationService: (any ContentModeratingServicing)?
    private var isConfigured = false

    var text = ""
    var selectedExpirationIndex = 1 // Default: 24hr
    var selectedLocation: CLLocationCoordinate2D?
    var selectedLocationName: String?
    private(set) var isCreating = false
    private(set) var errorMessage: String?
    private(set) var didCreatePing = false

    var characterCount: Int { text.count }
    var isOverLimit: Bool { text.count > Constants.Ping.maxTextLength }

    var canCreate: Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !isOverLimit && !isCreating && selectedLocation != nil
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

    private var selectedExpiration: TimeInterval {
        Constants.Ping.expirationPresets[selectedExpirationIndex]
    }

    private static let expirationLabels = ["6h", "24h", "48h"]

    func expirationLabel(for index: Int) -> String {
        Self.expirationLabels[index]
    }

    func configure(
        authService: any AuthServicing,
        pingService: any PingServicing,
        chatService: any ChatServicing,
        locationService: any LocationServicing,
        contentModerationService: any ContentModeratingServicing
    ) {
        guard !isConfigured else { return }
        self.authService = authService
        self.pingService = pingService
        self.chatService = chatService
        self.locationService = locationService
        self.contentModerationService = contentModerationService
        isConfigured = true
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

            let ping = Ping(
                creatorId: currentUser.uid,
                text: trimmed,
                location: GeoPoint(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                ),
                geohash: "",
                expiresAt: Date.now.addingTimeInterval(selectedExpiration),
                status: .active
            )

            try await pingService.createPingWithChat(ping)
            didCreatePing = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
