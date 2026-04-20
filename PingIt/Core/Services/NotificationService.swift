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

        try? await db
            .collection(Constants.Firestore.usersCollection)
            .document(userId)
            .updateData(["fcmToken": token])
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
        if let pingId = userInfo["pingId"] as? String {
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
