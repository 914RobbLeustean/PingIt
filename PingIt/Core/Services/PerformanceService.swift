import FirebasePerformance

@Observable
@MainActor
final class PerformanceService: PerformanceServicing {

    nonisolated func startTrace(name: String) -> PerformanceTrace? {
        guard let trace = Performance.startTrace(name: name) else { return nil }
        return FirebasePerformanceTrace(trace: trace)
    }
}

private struct FirebasePerformanceTrace: PerformanceTrace {
    let trace: Trace

    func setValue(_ value: Int64, forAttribute attribute: String) {
        trace.setValue(value, forMetric: attribute)
    }

    func stop() {
        trace.stop()
    }
}
