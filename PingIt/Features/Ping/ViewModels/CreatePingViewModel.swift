import Foundation
import CoreLocation
import FirebaseAuth
import FirebaseFirestore

@Observable
final class CreatePingViewModel {
    private let authService: AuthService
    private let pingService: PingService
    private let chatService: ChatService
    private let locationService: LocationService

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

    init(
        authService: AuthService,
        pingService: PingService,
        chatService: ChatService,
        locationService: LocationService
    ) {
        self.authService = authService
        self.pingService = pingService
        self.chatService = chatService
        self.locationService = locationService
    }

    func useCurrentLocation() {
        guard let location = locationService.currentLocation else {
            errorMessage = PingItError.locationUnavailable.localizedDescription
            return
        }
        selectedLocation = location.coordinate
        selectedLocationName = "Current Location"
    }

    func createPing() async {
        isCreating = true
        errorMessage = nil
        defer { isCreating = false }

        do {
            guard let currentUser = authService.currentUser else {
                throw PingItError.notAuthenticated
            }

            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw PingItError.pingTextEmpty
            }
            guard trimmed.count <= Constants.Ping.maxTextLength else {
                throw PingItError.pingTextTooLong
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

            try await pingService.createPingWithChat(ping, chatService: chatService)
            didCreatePing = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
