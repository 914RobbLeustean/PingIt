protocol CrashReportingServicing {
    func setUserId(_ userId: String?)
    func record(error: Error)
}
