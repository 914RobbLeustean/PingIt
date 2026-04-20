import CoreLocation
import FirebaseFirestore

struct PingCluster: Identifiable {
    let id: String
    let pings: [Ping]
    let center: CLLocationCoordinate2D
    let containsHotPing: Bool

    var count: Int { pings.count }

    init(pings: [Ping], hotPingIds: Set<String>) {
        self.pings = pings
        self.id = pings.compactMap(\.id).joined(separator: "-")
        self.containsHotPing = pings.contains { hotPingIds.contains($0.id ?? "") }

        let totalLat = pings.reduce(0.0) { $0 + $1.location.latitude }
        let totalLon = pings.reduce(0.0) { $0 + $1.location.longitude }
        let count = Double(pings.count)
        self.center = CLLocationCoordinate2D(
            latitude: totalLat / count,
            longitude: totalLon / count
        )
    }
}
