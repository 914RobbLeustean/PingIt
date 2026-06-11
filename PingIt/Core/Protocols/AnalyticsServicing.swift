protocol AnalyticsServicing {
    func logEvent(_ name: String, parameters: [String: Any]?)
    func setUserId(_ userId: String?)
}
