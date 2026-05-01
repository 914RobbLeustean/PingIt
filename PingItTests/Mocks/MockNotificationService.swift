import Observation
@testable import PingIt

@Observable
@MainActor
final class MockNotificationService: NotificationServicing {
    var requestPermissionCalled = false
    var registerFCMTokenCalled = false
    var updateLastKnownLocationCalled = false
    var lastLatitude: Double?
    var lastLongitude: Double?
    var permissionGranted = true

    func requestPermission() async -> Bool {
        requestPermissionCalled = true
        return permissionGranted
    }

    func registerFCMToken() async {
        registerFCMTokenCalled = true
    }

    func updateLastKnownLocation(latitude: Double, longitude: Double) async {
        updateLastKnownLocationCalled = true
        lastLatitude = latitude
        lastLongitude = longitude
    }
}
