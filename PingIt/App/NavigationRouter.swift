import Foundation

@Observable
@MainActor
final class NavigationRouter {
    var pendingPingId: String?
    var pendingRecapId: String?
}
