import CoreLocation

enum Constants {
    enum Cluj {
        static let centerLatitude = 46.7712
        static let centerLongitude = 23.6236
        static let center = CLLocationCoordinate2D(
            latitude: centerLatitude,
            longitude: centerLongitude
        )
        static let radiusKilometers = 15.0
    }

    enum Ping {
        static let maxTextLength = 280
        static let expirationPresets: [TimeInterval] = [
            6 * 3600,   // 6 hours
            24 * 3600,  // 24 hours
            48 * 3600   // 48 hours
        ]
    }

    enum RateLimit {
        static let maxPingsPerHour = 5
        static let maxPingsPerDay = 10
        static let maxMessagesPerTenSeconds = 6
    }

    enum Firestore {
        static let usersCollection = "users"
        static let pingsCollection = "pings"
        static let chatsCollection = "chats"
        static let chatMessagesCollection = "chatMessages"
        static let chatParticipantsCollection = "chatParticipants"
    }
}
