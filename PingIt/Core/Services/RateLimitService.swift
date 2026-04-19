import Foundation

@Observable
@MainActor
final class RateLimitService: RateLimitServicing {
    private enum Keys {
        static let pingTimestamps = "com.pingit.rateLimit.pingTimestamps"
        static let messageTimestamps = "com.pingit.rateLimit.messageTimestamps"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func canCreatePing() -> RateLimitResult {
        #if DEBUG
        return .allowed
        #else
        let now = Date.now
        let timestamps = loadTimestamps(for: Keys.pingTimestamps)

        let oneHourAgo = now.addingTimeInterval(-3600)
        let pingsInLastHour = timestamps.filter { $0 > oneHourAgo }
        if pingsInLastHour.count >= Constants.RateLimit.maxPingsPerHour {
            let oldestInWindow = pingsInLastHour.min() ?? now
            let retryAfter = oldestInWindow.timeIntervalSince(oneHourAgo)
            return .limited(retryAfter: retryAfter)
        }

        let oneDayAgo = now.addingTimeInterval(-86400)
        let pingsInLastDay = timestamps.filter { $0 > oneDayAgo }
        if pingsInLastDay.count >= Constants.RateLimit.maxPingsPerDay {
            let oldestInWindow = pingsInLastDay.min() ?? now
            let retryAfter = oldestInWindow.timeIntervalSince(oneDayAgo)
            return .limited(retryAfter: retryAfter)
        }

        return .allowed
        #endif
    }

    func canSendMessage() -> RateLimitResult {
        #if DEBUG
        return .allowed
        #else
        let now = Date.now
        let timestamps = loadTimestamps(for: Keys.messageTimestamps)

        let tenSecondsAgo = now.addingTimeInterval(-10)
        let messagesInWindow = timestamps.filter { $0 > tenSecondsAgo }
        if messagesInWindow.count >= Constants.RateLimit.maxMessagesPerTenSeconds {
            let oldestInWindow = messagesInWindow.min() ?? now
            let retryAfter = oldestInWindow.timeIntervalSince(tenSecondsAgo)
            return .limited(retryAfter: retryAfter)
        }

        return .allowed
        #endif
    }

    func recordPingCreation() {
        var timestamps = loadTimestamps(for: Keys.pingTimestamps)
        timestamps.append(Date.now)
        let oneDayAgo = Date.now.addingTimeInterval(-86400)
        timestamps = timestamps.filter { $0 > oneDayAgo }
        saveTimestamps(timestamps, for: Keys.pingTimestamps)
    }

    func recordMessageSent() {
        var timestamps = loadTimestamps(for: Keys.messageTimestamps)
        timestamps.append(Date.now)
        let tenSecondsAgo = Date.now.addingTimeInterval(-10)
        timestamps = timestamps.filter { $0 > tenSecondsAgo }
        saveTimestamps(timestamps, for: Keys.messageTimestamps)
    }

    // MARK: - Storage

    private func loadTimestamps(for key: String) -> [Date] {
        guard let data = defaults.data(forKey: key),
              let timestamps = try? JSONDecoder().decode([Date].self, from: data) else {
            return []
        }
        return timestamps
    }

    private func saveTimestamps(_ timestamps: [Date], for key: String) {
        if let data = try? JSONEncoder().encode(timestamps) {
            defaults.set(data, forKey: key)
        }
    }
}
