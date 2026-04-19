import Foundation
import FirebaseAuth

enum PingItError: LocalizedError {
    // Auth
    case notAuthenticated
    case signUpFailed(underlying: Error)
    case signInFailed(underlying: Error)
    case signOutFailed(underlying: Error)
    case passwordResetFailed(underlying: Error)
    case emailVerificationFailed(underlying: Error)
    case emailNotVerified

    // Auth — user-friendly Firebase mappings
    case emailAlreadyInUse
    case invalidEmail
    case weakPassword
    case userNotFound
    case wrongPassword
    case networkError

    // Validation
    case pingTextTooLong
    case pingTextEmpty
    case locationOutsideBoundary
    case invalidExpiration
    case passwordsDoNotMatch
    case termsNotAccepted
    case passwordTooShort
    case passwordMissingUppercase
    case passwordMissingLowercase
    case passwordMissingDigit

    // Network / Firestore
    case firestoreReadFailed(underlying: Error)
    case firestoreWriteFailed(underlying: Error)
    case documentNotFound

    // Rate Limiting
    case pingRateLimitExceeded
    case messageRateLimitExceeded
    case rateLimited(retryAfterMinutes: Int)

    // Location
    case locationPermissionDenied
    case locationUnavailable

    // Content Moderation
    case contentModerated(reason: String)

    // Blocking
    case blockFailed(underlying: Error)
    case unblockFailed(underlying: Error)
    case cannotBlockSelf

    // Reporting
    case reportFailed(underlying: Error)
    case reportAlreadySubmitted

    // Profile
    case usernameTooShort
    case usernameTooLong
    case usernameInvalidCharacters
    case usernameAlreadyTaken
    case profileImageTooLarge
    case profileImageUploadFailed(underlying: Error)
    case profileUpdateFailed(underlying: Error)

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
        case .passwordResetFailed(let error):
            "Failed to send password reset: \(error.localizedDescription)"
        case .emailVerificationFailed:
            "Failed to send verification email. Please try again."
        case .emailNotVerified:
            "Please verify your email before creating pings."
        case .emailAlreadyInUse:
            "An account with this email already exists."
        case .invalidEmail:
            "Please enter a valid email address."
        case .weakPassword:
            "Password is too weak. Please choose a stronger password."
        case .userNotFound:
            "No account found with this email."
        case .wrongPassword:
            "Incorrect email or password. Please try again."
        case .networkError:
            "A network error occurred. Please check your connection and try again."
        case .pingTextTooLong:
            "Ping text cannot exceed \(Constants.Ping.maxTextLength) characters."
        case .pingTextEmpty:
            "Ping text cannot be empty."
        case .locationOutsideBoundary:
            "Pings can only be created within Cluj-Napoca."
        case .invalidExpiration:
            "Invalid expiration time selected."
        case .passwordsDoNotMatch:
            "Passwords do not match."
        case .termsNotAccepted:
            "You must accept the Terms of Service to create an account."
        case .passwordTooShort:
            "Password must be at least \(Constants.Password.minLength) characters."
        case .passwordMissingUppercase:
            "Password must contain at least one uppercase letter."
        case .passwordMissingLowercase:
            "Password must contain at least one lowercase letter."
        case .passwordMissingDigit:
            "Password must contain at least one number."
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
        case .rateLimited(let minutes):
            "You're creating pings too quickly. Try again in \(minutes) minute\(minutes == 1 ? "" : "s")."
        case .locationPermissionDenied:
            "Location access is required. Please enable it in Settings."
        case .locationUnavailable:
            "Unable to determine your location."
        case .usernameTooShort:
            "Username must be at least \(Constants.Username.minLength) characters."
        case .usernameTooLong:
            "Username cannot exceed \(Constants.Username.maxLength) characters."
        case .usernameInvalidCharacters:
            "Username can only contain letters, numbers, and underscores."
        case .usernameAlreadyTaken:
            "This username is already taken. Please choose another."
        case .profileImageTooLarge:
            "Profile image must be under 5 MB."
        case .profileImageUploadFailed(let error):
            "Failed to upload profile image: \(error.localizedDescription)"
        case .profileUpdateFailed(let error):
            "Failed to update profile: \(error.localizedDescription)"
        case .contentModerated(let reason):
            reason
        case .blockFailed:
            "Failed to block user. Please try again."
        case .unblockFailed:
            "Failed to unblock user. Please try again."
        case .cannotBlockSelf:
            "You cannot block yourself."
        case .reportFailed:
            "Failed to submit report. Please try again."
        case .reportAlreadySubmitted:
            "You have already reported this content."
        }
    }

    /// Maps a Firebase Auth error to a user-friendly PingItError.
    static func from(authError: Error) -> PingItError {
        let nsError = authError as NSError
        guard let code = AuthErrorCode(rawValue: nsError.code) else {
            return .signInFailed(underlying: authError)
        }
        switch code {
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .invalidEmail:
            return .invalidEmail
        case .weakPassword:
            return .weakPassword
        case .userNotFound:
            return .userNotFound
        case .wrongPassword:
            return .wrongPassword
        case .networkError:
            return .networkError
        case .invalidCredential:
            // Returned when email+password combination is incorrect
            return .wrongPassword
        case .tooManyRequests:
            return .networkError
        default:
            return .signInFailed(underlying: authError)
        }
    }
}
