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
        static let maxDescriptionLength = 500
        static let expirationPresets: [TimeInterval] = [
            6 * 3600,   // 6 hours
            24 * 3600,  // 24 hours
            48 * 3600   // 48 hours
        ]
        static let customDurationMin: TimeInterval = 3600
        static let customDurationMax: TimeInterval = 48 * 3600
    }

    enum RateLimit {
        static let maxPingsPerHour = 5
        static let maxPingsPerDay = 10
        static let maxMessagesPerTenSeconds = 6
    }

    enum Email {
        static let validationPattern = "^[A-Za-z0-9._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}$"
    }

    enum Password {
        static let minLength = 8
    }

    enum Username {
        static let minLength = 3
        static let maxLength = 20
        static let allowedCharacterPattern = "^[a-zA-Z0-9_]+$"
        static let uniquenessCheckDebounceMilliseconds: UInt64 = 500
    }

    enum Storage {
        static let profilePicturesPath = "profile_pictures"
        static let pingImagesPath = "ping_images"
        static let recapPhotosPath = "recap_photos"
        static let maxImageSizeBytes: Int64 = 5 * 1024 * 1024
        static let imageCompressionQuality: Double = 0.8
        static let pingImageMaxDimension: Double = 1024
    }

    enum Recap {
        static let maxPhotosPerUser = 3
    }

    enum Reaction {
        static let available: [(key: String, emoji: String)] = [
            ("thumbsUp", "👍"), ("heart", "❤️"), ("laugh", "😂"), ("wow", "😮"),
            ("sad", "😢"), ("fire", "🔥"), ("thumbsDown", "👎"), ("party", "🎉")
        ]
    }

    enum MessageType {
        static let text = "text"
        static let location = "location"
    }

    enum Firestore {
        static let usersCollection = "users"
        static let usernamesCollection = "usernames"
        static let pingsCollection = "pings"
        static let chatsCollection = "chats"
        static let chatMessagesCollection = "chatMessages"
        static let chatParticipantsCollection = "chatParticipants"
        static let blocksCollection = "blocks"
        static let reportsCollection = "reports"
        static let boostsCollection = "boosts"
        static let rsvpsCollection = "rsvps"
        static let followsCollection = "follows"
        static let pingRecapsCollection = "pingRecaps"
        static let recapPhotosSubcollection = "photos"
    }
}
