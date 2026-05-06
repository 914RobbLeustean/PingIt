import FirebaseCrashlytics

@Observable
@MainActor
final class CrashReportingService: CrashReportingServicing {
    func setUserId(_ userId: String?) {
        Crashlytics.crashlytics().setUserID(userId ?? "")
    }

    func record(error: Error) {
        Crashlytics.crashlytics().record(error: error)
    }
}
