import Foundation
import FirebaseFunctions

@MainActor @Observable
final class DataExportService: DataExportServicing {

    nonisolated func exportUserData() async throws -> Data {
        let functions = Functions.functions(region: "europe-west3")
        let result = try await functions.httpsCallable("exportUserData").call()

        let jsonData = try JSONSerialization.data(
            withJSONObject: result.data,
            options: [.prettyPrinted, .sortedKeys]
        )
        return jsonData
    }
}
