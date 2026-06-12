import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import UserNotifications

@Observable
final class NotificationService: NSObject, NotificationServicing {
    private let db = Firestore.firestore()

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
            return granted
        } catch {
            return false
        }
    }

    func registerFCMToken() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        guard let token = Messaging.messaging().fcmToken else { return }

        // setData(merge:) rather than updateData: the token can arrive before
        // the user doc exists (token refresh during a fresh sign-up race),
        // and updateData throws NOT_FOUND in that case — silently dropping the
        // token so the device never receives notifications. Merge upserts it.
        try? await db
            .collection(Constants.Firestore.usersCollection)
            .document(userId)
            .setData(["fcmToken": token], merge: true)
    }

    func updateLastKnownLocation(latitude: Double, longitude: Double) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        try? await db
            .collection(Constants.Firestore.usersCollection)
            .document(userId)
            .updateData([
                "lastKnownLocation": [
                    "latitude": latitude,
                    "longitude": longitude,
                ],
            ])
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let pingId = userInfo["pingId"] as? String else { return }

        // Recap notifications point at an expired ping; route them to the
        // recap (whose document id equals the ping id) instead of the
        // unavailable ping. `recap_invite` is sent to attendees when a ping
        // expires; `followed_recap_photo` when a followed user posts a photo.
        switch userInfo["type"] as? String {
        case "recap_invite", "followed_recap_photo":
            NotificationCenter.default.post(
                name: .init("PingItOpenRecap"),
                object: nil,
                userInfo: ["recapId": pingId]
            )
        default:
            NotificationCenter.default.post(
                name: .init("PingItOpenPing"),
                object: nil,
                userInfo: ["pingId": pingId]
            )
        }
    }
}

extension NotificationService: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard fcmToken != nil else { return }
        Task { @MainActor in
            await self.registerFCMToken()
        }
    }
}
