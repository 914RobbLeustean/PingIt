import Foundation
import FirebaseDatabase

/// Provides a server-corrected "now" using Firebase Realtime Database's
/// `.info/serverTimeOffset`. This offset is automatically maintained by
/// the SDK and accounts for network latency.
///
/// Usage: Replace `Date.now` with `ServerTime.now` wherever cross-device
/// time consistency matters (countdowns, expiration checks, ping creation).
enum ServerTime {
    /// Offset in milliseconds between server time and device clock.
    /// Positive means server is ahead of device; negative means behind.
    /// Updated automatically by Firebase RTDB when connected.
    private(set) static var offsetMilliseconds: Double = 0

    /// Server-corrected current time.
    static var now: Date {
        Date.now.addingTimeInterval(offsetMilliseconds / 1000)
    }

    /// Start observing the server time offset. Call once at app launch.
    static func startObserving() {
        let ref = Database.database().reference(withPath: ".info/serverTimeOffset")
        ref.observe(.value) { snapshot in
            if let offset = snapshot.value as? Double {
                offsetMilliseconds = offset
            }
        }
    }
}
