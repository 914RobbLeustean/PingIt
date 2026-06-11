import Foundation

protocol DataExportServicing: Sendable {
    func exportUserData() async throws -> Data
}
