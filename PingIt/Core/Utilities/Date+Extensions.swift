import Foundation

extension Date {
    /// Returns a human-readable countdown string like "2h 15m remaining"
    var countdownDescription: String {
        let remaining = timeIntervalSinceNow
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
    var relativeDescription: String {
        formatted(.relative(presentation: .named, unitsStyle: .wide))
    }
}
