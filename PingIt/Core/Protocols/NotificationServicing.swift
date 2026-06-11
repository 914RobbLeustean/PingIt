protocol NotificationServicing {
    func requestPermission() async -> Bool
    func registerFCMToken() async
    func updateLastKnownLocation(latitude: Double, longitude: Double) async
}
