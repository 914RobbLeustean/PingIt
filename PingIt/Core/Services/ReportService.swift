import Foundation
import FirebaseAuth
import FirebaseFunctions

@Observable
@MainActor
final class ReportService: ReportServicing {
    private let functions = Functions.functions(region: "europe-west3")

    func submitReport(
        targetType: Report.ReportTargetType,
        targetId: String,
        targetOwnerId: String,
        reason: Report.ReportReason,
        details: String?,
        targetContent: String?,
        targetImageURL: String?
    ) async throws {
        guard Auth.auth().currentUser != nil else {
            throw PingItError.notAuthenticated
        }

        do {
            var payload: [String: Any] = [
                "targetType": targetType.rawValue,
                "targetId": targetId,
                "targetOwnerId": targetOwnerId,
                "reason": reason.rawValue
            ]
            if let details {
                payload["details"] = details
            }
            if let targetContent {
                payload["targetContent"] = targetContent
            }
            if let targetImageURL {
                payload["targetImageURL"] = targetImageURL
            }

            _ = try await functions.httpsCallable("submitReport").call(payload)
        } catch let error as NSError
            where error.domain == FunctionsErrorDomain
                && error.code == FunctionsErrorCode.alreadyExists.rawValue {
            throw PingItError.reportAlreadySubmitted
        } catch {
            throw PingItError.reportFailed(underlying: error)
        }
    }
}
