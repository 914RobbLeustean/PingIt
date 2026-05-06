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
    private var rateLimitService: (any RateLimitServicing)?
    private var analyticsService: (any AnalyticsServicing)?
    private var isConfigured = false

    var text = ""
    var selectedExpirationIndex = 1 // Default: 24hr
    var isCustomDuration = false
    var customExpiryDate = Calendar.current.date(byAdding: .hour, value: 6, to: Date.now) ?? Date.now
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

    private static let presetLabels = ["6h", "24h", "48h", "Custom"]

    var selectedExpiration: TimeInterval {
        if isCustomDuration {
            let duration = customExpiryDate.timeIntervalSince(Date.now)
            return min(max(duration, Constants.Ping.customDurationMin), Constants.Ping.customDurationMax)
        }
        return Constants.Ping.expirationPresets[selectedExpirationIndex]
    }

    var customExpiryRange: ClosedRange<Date> {
        let minDate = Date.now.addingTimeInterval(Constants.Ping.customDurationMin)
        let endOfDay = Calendar.current.startOfDay(for: Date.now).addingTimeInterval(24 * 3600 - 60)
        let maxDate = max(minDate, endOfDay)
        return minDate...maxDate
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

            let ping = Ping(
                creatorId: currentUser.uid,
                text: trimmed,
                location: GeoPoint(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                ),
                geohash: "",
                expiresAt: ServerTime.now.addingTimeInterval(selectedExpiration),
                status: .active
            )

            try await pingService.createPingWithChat(ping)
            didCreatePing = true
            rateLimitService?.recordPingCreation()

            let durationHours = Int(selectedExpiration / 3600)
            analyticsService?.logEvent(AnalyticsService.EventName.pingCreated, parameters: [
                AnalyticsService.ParameterName.durationType: isCustomDuration ? "custom" : "preset",
                AnalyticsService.ParameterName.durationHours: durationHours
            ])
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
