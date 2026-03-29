import Foundation

enum PingItError: LocalizedError {
    // Auth
    case notAuthenticated
    case signUpFailed(underlying: Error)
    case signInFailed(underlying: Error)
    case signOutFailed(underlying: Error)

    // Validation
    case pingTextTooLong
    case pingTextEmpty
    case locationOutsideBoundary
    case invalidExpiration

    // Network / Firestore
    case firestoreReadFailed(underlying: Error)
    case firestoreWriteFailed(underlying: Error)
    case documentNotFound

    // Rate Limiting
    case pingRateLimitExceeded
    case messageRateLimitExceeded

    // Location
    case locationPermissionDenied
    case locationUnavailable

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            "You must be signed in to perform this action."
        case .signUpFailed(let error):
            "Sign up failed: \(error.localizedDescription)"
        case .signInFailed(let error):
            "Sign in failed: \(error.localizedDescription)"
        case .signOutFailed(let error):
            "Sign out failed: \(error.localizedDescription)"
        case .pingTextTooLong:
            "Ping text cannot exceed \(Constants.Ping.maxTextLength) characters."
        case .pingTextEmpty:
            "Ping text cannot be empty."
        case .locationOutsideBoundary:
            "Pings can only be created within Cluj-Napoca."
        case .invalidExpiration:
            "Invalid expiration time selected."
        case .firestoreReadFailed(let error):
            "Failed to load data: \(error.localizedDescription)"
        case .firestoreWriteFailed(let error):
            "Failed to save data: \(error.localizedDescription)"
        case .documentNotFound:
            "The requested item was not found."
        case .pingRateLimitExceeded:
            "You've reached the ping creation limit. Please try again later."
        case .messageRateLimitExceeded:
            "You're sending messages too quickly. Please slow down."
        case .locationPermissionDenied:
            "Location access is required. Please enable it in Settings."
        case .locationUnavailable:
            "Unable to determine your location."
        }
    }
}
