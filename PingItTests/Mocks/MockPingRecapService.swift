import Foundation
import Observation
@testable import PingIt

@Observable
@MainActor
final class MockPingRecapService: PingRecapServicing {
    var errorToThrow: Error?

    private(set) var submitRecapPhotoCalled = false
    private(set) var lastSubmittedRecapId: String?
    private(set) var lastSubmittedSubmitterId: String?
    private(set) var lastSubmittedImageData: Data?

    private(set) var activeRecapsCallback: (@Sendable (Result<[PingRecap], Error>) -> Void)?
    private(set) var photosCallback: (@Sendable (Result<[PingRecapPhoto], Error>) -> Void)?
    private(set) var removeCalled = false

    func observeActiveRecaps(
        onUpdate: @escaping @Sendable (Result<[PingRecap], Error>) -> Void
    ) -> ListenerHandle {
        activeRecapsCallback = onUpdate
        return ListenerHandle { [weak self] in
            self?.removeCalled = true
        }
    }

    func observePhotos(
        recapId: String,
        onUpdate: @escaping @Sendable (Result<[PingRecapPhoto], Error>) -> Void
    ) -> ListenerHandle {
        photosCallback = onUpdate
        return ListenerHandle { [weak self] in
            self?.removeCalled = true
        }
    }

    func submitRecapPhoto(recapId: String, submitterId: String, imageData: Data) async throws {
        submitRecapPhotoCalled = true
        lastSubmittedRecapId = recapId
        lastSubmittedSubmitterId = submitterId
        lastSubmittedImageData = imageData
        if let error = errorToThrow { throw error }
    }
}
