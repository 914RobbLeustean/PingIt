protocol PerformanceServicing: Sendable {
    func startTrace(name: String) -> PerformanceTrace?
}

protocol PerformanceTrace: Sendable {
    func setValue(_ value: Int64, forAttribute attribute: String)
    func stop()
}
