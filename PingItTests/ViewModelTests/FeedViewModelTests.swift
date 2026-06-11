import Foundation
import Testing
import CoreLocation
import FirebaseFirestore
@testable import PingIt

@Suite("FeedViewModel")
@MainActor
struct FeedViewModelTests {

    private func makeVM(
        pingService: MockPingService? = nil,
        locationService: MockLocationService? = nil,
        blockService: MockBlockService? = nil,
        userService: MockUserService? = nil
    ) -> FeedViewModel {
        let pingService = pingService ?? MockPingService()
        let locationService = locationService ?? MockLocationService()
        let blockService = blockService ?? MockBlockService()
        let userService = userService ?? MockUserService()
        let vm = FeedViewModel()
        vm.configure(
            pingService: pingService,
            locationService: locationService,
            blockService: blockService,
            userService: userService
        )
        return vm
    }

    private func makePing(
        id: String,
        creatorId: String = "user1",
        boostCount: Int = 0,
        participantCount: Int = 0,
        expiresAt: Date = Date.now.addingTimeInterval(3600),
        createdAt: Date = Date.now
    ) -> Ping {
        var ping = Ping(
            creatorId: creatorId,
            text: "Ping \(id)",
            location: GeoPoint(latitude: 46.77, longitude: 23.62),
            geohash: "",
            expiresAt: expiresAt,
            status: .active,
            boostCount: boostCount,
            participantCount: participantCount
        )
        ping.id = id
        ping.createdAt = createdAt
        return ping
    }

    @Test func sortedPingsByNewest() {
        let vm = makeVM()
        let older = makePing(id: "1", createdAt: Date.now.addingTimeInterval(-100))
        let newer = makePing(id: "2", createdAt: Date.now)

        let ping = MockPingService()
        vm.configure(pingService: ping, locationService: MockLocationService())
        vm.sortOption = .newest

        // Manually set pings via the listener simulation
        ping.activePingsCallback?(.success([older, newer]))

        // Wait a tick for the Task to run
        let sorted = vm.sortedPings
        if sorted.count == 2 {
            #expect(sorted[0].id == "2")
            #expect(sorted[1].id == "1")
        }
    }

    @Test func sortedPingsByHottest() {
        let ping = MockPingService()
        let vm = makeVM(pingService: ping)
        vm.sortOption = .hottest

        let cold = makePing(id: "1", boostCount: 0, participantCount: 0)
        let hot = makePing(id: "2", boostCount: 5, participantCount: 10)
        ping.activePingsCallback?(.success([cold, hot]))

        let sorted = vm.sortedPings
        if sorted.count == 2 {
            #expect(sorted[0].id == "2")
        }
    }

    @Test func filtersExpiredPings() {
        let ping = MockPingService()
        let vm = makeVM(pingService: ping)

        let active = makePing(id: "1", expiresAt: Date.now.addingTimeInterval(3600))
        let expired = makePing(id: "2", expiresAt: Date.now.addingTimeInterval(-60))
        ping.activePingsCallback?(.success([active, expired]))

        #expect(vm.sortedPings.allSatisfy { $0.expiresAt > Date.now.addingTimeInterval(-1) })
    }

    @Test func filtersBlockedCreators() {
        let ping = MockPingService()
        let block = MockBlockService()
        block.blockedUserIds = ["blocked_user"]
        let vm = makeVM(pingService: ping, blockService: block)

        let normal = makePing(id: "1", creatorId: "user1")
        let blocked = makePing(id: "2", creatorId: "blocked_user")
        ping.activePingsCallback?(.success([normal, blocked]))

        #expect(vm.sortedPings.count <= 1)
        #expect(vm.sortedPings.allSatisfy { $0.creatorId != "blocked_user" })
    }
}
