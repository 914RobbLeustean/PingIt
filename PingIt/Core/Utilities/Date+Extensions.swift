import Foundation

extension Date {
    /// Returns a human-readable countdown string like "2h 15m remaining"
    /// Uses server-corrected time so all users see consistent countdowns.
    var countdownDescription: String {
        let remaining = timeIntervalSince(ServerTime.now)
        guard remaining > 0 else { return "Expired" }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        } else if minutes > 0 {
            return "\(minutes)m remaining"
        } else {
            return "Less than a minute remaining"
        }
    }

    /// Returns a relative description like "5 minutes ago"
    /// Uses server-corrected time for consistent cross-device display.
    var relativeDescription: String {
        let offset = ServerTime.now.timeIntervalSince(Date.now)
        let corrected = addingTimeInterval(-offset)
        return corrected.formatted(.relative(presentation: .named))
    }
}
