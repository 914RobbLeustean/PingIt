import Testing
import Foundation
import FirebaseFirestore
@testable import PingIt

struct HeatCellTests {

    private func makePing(
        lat: Double = 46.7700,
        lon: Double = 23.6200,
        createdAgo: TimeInterval,
        boostCount: Int = 0,
        now: Date
    ) -> Ping {
        var ping = Ping(
            creatorId: "user1",
            text: "Test",
            location: GeoPoint(latitude: lat, longitude: lon),
            geohash: "",
            expiresAt: now.addingTimeInterval(3600),
            status: .expired,
            boostCount: boostCount
        )
        ping.createdAt = now.addingTimeInterval(-createdAgo)
        ping.id = UUID().uuidString
        return ping
    }

    // MARK: - Weight

    @Test func freshPingHasFullRecencyWeight() {
        let now = Date.now
        let weight = HeatmapBuilder.weight(createdAt: now, boostCount: 0, now: now)
        #expect(abs(weight - 1.0) < 0.001)
    }

    @Test func weekOldPingHasReducedWeight() {
        let now = Date.now
        let weekAgo = now.addingTimeInterval(-HeatmapBuilder.windowDays * 24 * 3600 + 1)
        let weight = HeatmapBuilder.weight(createdAt: weekAgo, boostCount: 0, now: now)
        #expect(abs(weight - 0.25) < 0.01)
    }

    @Test func pingOutsideWindowHasZeroWeight() {
        let now = Date.now
        let tooOld = now.addingTimeInterval(-8 * 24 * 3600)
        #expect(HeatmapBuilder.weight(createdAt: tooOld, boostCount: 0, now: now) == 0)
    }

    @Test func boostsIncreaseWeight() {
        let now = Date.now
        let plain = HeatmapBuilder.weight(createdAt: now, boostCount: 0, now: now)
        let boosted = HeatmapBuilder.weight(createdAt: now, boostCount: 5, now: now)
        #expect(boosted > plain)
        #expect(abs(boosted - 1.75) < 0.001)
    }

    @Test func boostWeightIsCapped() {
        let now = Date.now
        let atCap = HeatmapBuilder.weight(createdAt: now, boostCount: 10, now: now)
        let overCap = HeatmapBuilder.weight(createdAt: now, boostCount: 50, now: now)
        #expect(atCap == overCap)
    }

    // MARK: - Bucketing

    @Test func nearbyPingsShareACell() {
        let now = Date.now
        let pings = [
            makePing(lat: 46.77000, lon: 23.62000, createdAgo: 3600, now: now),
            makePing(lat: 46.77005, lon: 23.62005, createdAgo: 3600, now: now),
        ]
        let cells = HeatmapBuilder.buildCells(from: pings, now: now)
        #expect(cells.count == 1)
    }

    @Test func distantPingsGetSeparateCells() {
        let now = Date.now
        let pings = [
            makePing(lat: 46.7700, lon: 23.6200, createdAgo: 3600, now: now),
            makePing(lat: 46.7800, lon: 23.6400, createdAgo: 3600, now: now),
        ]
        let cells = HeatmapBuilder.buildCells(from: pings, now: now)
        #expect(cells.count == 2)
    }

    @Test func busiestCellHasFullIntensity() {
        let now = Date.now
        var pings = [makePing(lat: 46.7800, lon: 23.6400, createdAgo: 3600, now: now)]
        pings += (0..<5).map { _ in makePing(lat: 46.7700, lon: 23.6200, createdAgo: 3600, now: now) }

        let cells = HeatmapBuilder.buildCells(from: pings, now: now)
        let maxIntensity = cells.map(\.intensity).max()
        #expect(maxIntensity == 1.0)
        #expect(cells.contains { $0.intensity < 1.0 })
    }

    @Test func pingsWithoutCreatedAtAreIgnored() {
        let now = Date.now
        var ping = makePing(createdAgo: 3600, now: now)
        ping.createdAt = nil
        #expect(HeatmapBuilder.buildCells(from: [ping], now: now).isEmpty)
    }

    @Test func emptyInputProducesNoCells() {
        #expect(HeatmapBuilder.buildCells(from: [], now: .now).isEmpty)
    }
}
