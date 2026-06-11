import Foundation
import CoreLocation
import FirebaseFirestore

/// One grid cell of the 7-day activity heatmap. Pings are bucketed into
/// ~130m cells; each cell's intensity is normalized against the busiest
/// cell so rendering is stable regardless of absolute activity volume.
struct HeatCell: Identifiable, Equatable {
    let id: String
    let center: CLLocationCoordinate2D
    /// Normalized 0...1 against the strongest cell.
    let intensity: Double

    static func == (lhs: HeatCell, rhs: HeatCell) -> Bool {
        lhs.id == rhs.id && lhs.intensity == rhs.intensity
    }
}

enum HeatmapBuilder {
    /// Grid cell size in degrees latitude (~130m).
    static let cellSize = 0.0012
    static let windowDays = 7.0

    /// Weight of a single ping: recent pings count more (1.0 fresh down to
    /// 0.25 at the window edge), boosted pings count more (up to 2.5x).
    static func weight(createdAt: Date, boostCount: Int, now: Date) -> Double {
        let age = now.timeIntervalSince(createdAt)
        let windowSeconds = windowDays * 24 * 3600
        guard age >= 0, age <= windowSeconds else { return 0 }
        let recency = 1.0 - (age / windowSeconds) * 0.75
        let boostFactor = 1.0 + Double(min(boostCount, 10)) * 0.15
        return recency * boostFactor
    }

    static func buildCells(from pings: [Ping], now: Date) -> [HeatCell] {
        var weights: [String: (latSum: Double, lonSum: Double, count: Int, weight: Double)] = [:]

        for ping in pings {
            guard let createdAt = ping.createdAt else { continue }
            let pingWeight = weight(createdAt: createdAt, boostCount: ping.boostCount, now: now)
            guard pingWeight > 0 else { continue }

            let latIndex = Int((ping.location.latitude / cellSize).rounded(.down))
            let lonIndex = Int((ping.location.longitude / cellSize).rounded(.down))
            let key = "\(latIndex)_\(lonIndex)"

            var cell = weights[key] ?? (0, 0, 0, 0)
            cell.latSum += ping.location.latitude
            cell.lonSum += ping.location.longitude
            cell.count += 1
            cell.weight += pingWeight
            weights[key] = cell
        }

        guard let maxWeight = weights.values.map(\.weight).max(), maxWeight > 0 else {
            return []
        }

        return weights.map { key, cell in
            HeatCell(
                id: key,
                center: CLLocationCoordinate2D(
                    latitude: cell.latSum / Double(cell.count),
                    longitude: cell.lonSum / Double(cell.count)
                ),
                intensity: cell.weight / maxWeight
            )
        }
    }
}
