import Foundation

/// Creator-only editing of a ping's text, description, and category.
/// Validation mirrors CreatePingViewModel; the write goes through the
/// server-authoritative updatePing callable and propagates to everyone
/// via the existing ping listeners.
@MainActor @Observable
final class EditPingViewModel {
    private let originalPing: Ping
    private var pingService: (any PingServicing)?
    private var contentModerationService: (any ContentModeratingServicing)?
    private var analyticsService: (any AnalyticsServicing)?
    private var isConfigured = false

    var text: String
    var descriptionText: String
    var selectedCategory: PingCategory?
    private(set) var isSaving = false
    private(set) var errorMessage: String?
    private(set) var didSave = false

    init(ping: Ping) {
        self.originalPing = ping
        self.text = ping.text
        self.descriptionText = ping.description ?? ""
        self.selectedCategory = ping.category.flatMap(PingCategory.init(rawValue:))
    }

    var characterCount: Int { text.count }
    var isOverLimit: Bool { text.count > Constants.Ping.maxTextLength }
    var descriptionCharacterCount: Int { descriptionText.count }
    var isDescriptionOverLimit: Bool { descriptionText.count > Constants.Ping.maxDescriptionLength }

    var hasChanges: Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed != originalPing.text
            || trimmedDescription != (originalPing.description ?? "")
            || selectedCategory?.rawValue != originalPing.category
    }

    var canSave: Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty
            && !isOverLimit
            && !isDescriptionOverLimit
            && selectedCategory != nil
            && hasChanges
            && !isSaving
    }

    func configure(
        pingService: any PingServicing,
        contentModerationService: any ContentModeratingServicing,
        analyticsService: (any AnalyticsServicing)? = nil
    ) {
        guard !isConfigured else { return }
        self.pingService = pingService
        self.contentModerationService = contentModerationService
        self.analyticsService = analyticsService
        isConfigured = true
    }

    func save() async {
        guard let pingService, let pingId = originalPing.id else { return }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw PingItError.pingTextEmpty
            }
            guard trimmed.count <= Constants.Ping.maxTextLength else {
                throw PingItError.pingTextTooLong
            }

            let trimmedDescription = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedDescription.count > Constants.Ping.maxDescriptionLength {
                throw PingItError.pingTextTooLong
            }

            guard let category = selectedCategory else {
                throw PingItError.pingTextEmpty
            }

            if let moderationService = contentModerationService {
                let result = moderationService.check(trimmed)
                if case .blocked(let reason) = result {
                    throw PingItError.contentModerated(reason: reason)
                }
                if !trimmedDescription.isEmpty {
                    let descResult = moderationService.check(trimmedDescription)
                    if case .blocked(let reason) = descResult {
                        throw PingItError.contentModerated(reason: reason)
                    }
                }
            }

            try await pingService.updatePing(
                pingId: pingId,
                text: trimmed,
                description: trimmedDescription.isEmpty ? nil : trimmedDescription,
                category: category.rawValue
            )
            didSave = true

            analyticsService?.logEvent(AnalyticsService.EventName.pingEdited, parameters: [
                AnalyticsService.ParameterName.pingId: pingId,
                AnalyticsService.ParameterName.category: category.rawValue,
            ])
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
