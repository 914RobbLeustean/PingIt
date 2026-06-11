import Testing
import CoreLocation
import FirebaseFirestore
@testable import PingIt

@Suite("MapViewModel")
@MainActor
struct MapViewModelTests {

    // MARK: - Helpers

    private func makeVM(
        pingService: MockPingService? = nil,
        locationService: MockLocationService? = nil
    ) -> MapViewModel {
        let pingService = pingService ?? MockPingService()
        let locationService = locationService ?? MockLocationService()
        let vm = MapViewModel()
        vm.configure(pingService: pingService, locationService: locationService)
        return vm
    }

    // MARK: - Location delegation

    @Test func userLocationDelegatesToLocationService() {
        let location = MockLocationService()
        location.currentLocation = CLLocation(latitude: 46.77, longitude: 23.62)
        let vm = makeVM(locationService: location)
        #expect(vm.userLocation?.coordinate.latitude == 46.77)
    }

    @Test func authorizationStatusDelegatesToLocationService() {
        let location = MockLocationService()
        location.authorizationStatus = .authorizedWhenInUse
        let vm = makeVM(locationService: location)
        #expect(vm.authorizationStatus == .authorizedWhenInUse)
    }

    @Test func requestLocationPermissionCallsService() {
        let location = MockLocationService()
        let vm = makeVM(locationService: location)
        vm.requestLocationPermission()
        #expect(location.requestAuthorizationCalled)
    }

    @Test func startLocationUpdatesCallsService() {
        let location = MockLocationService()
        let vm = makeVM(locationService: location)
        vm.startLocationUpdates()
        #expect(location.startUpdatingCalled)
    }

    @Test func stopLocationUpdatesCallsService() {
        let location = MockLocationService()
        let vm = makeVM(locationService: location)
        vm.stopLocationUpdates()
        #expect(location.stopUpdatingCalled)
    }

    // MARK: - Listener lifecycle

    @Test func startObservingAttachesListener() {
        let ping = MockPingService()
        let vm = makeVM(pingService: ping)
        vm.startObserving()
        #expect(ping.activePingsCallback != nil)
    }

    @Test func stopObservingCallsRemoveOnListener() {
        let ping = MockPingService()
        let vm = makeVM(pingService: ping)
        vm.startObserving()
        vm.stopObserving()
        #expect(ping.removeCalled)
    }

    @Test func stopObservingAllowsReattach() {
        let ping = MockPingService()
        let vm = makeVM(pingService: ping)
        vm.startObserving()
        vm.stopObserving()
        // After stop, pings can be observed again
        vm.startObserving()
        #expect(ping.activePingsCallback != nil)
    }

    // MARK: - Blocking filter

    @Test("Blocked user pings are filtered from map")
    func blockedUserPingsFiltered() async {
        let mockPingService = MockPingService()
        let mockLocationService = MockLocationService()
        let mockBlockService = MockBlockService()
        mockBlockService.blockedUserIds = ["blocked_user"]

        let vm = MapViewModel()
        vm.configure(pingService: mockPingService, locationService: mockLocationService, blockService: mockBlockService)
        vm.startObserving()

        let normalPing = Ping(
            creatorId: "user1",
            text: "Visible ping",
            location: .init(latitude: 46.77, longitude: 23.62),
            geohash: "",
            expiresAt: Date.now.addingTimeInterval(3600),
            status: .active
        )
        let blockedPing = Ping(
            creatorId: "blocked_user",
            text: "Blocked user ping",
            location: .init(latitude: 46.78, longitude: 23.63),
            geohash: "",
            expiresAt: Date.now.addingTimeInterval(3600),
            status: .active
        )

        mockPingService.simulateUpdate(pings: [normalPing, blockedPing])
        try? await Task.sleep(for: .milliseconds(50))

        #expect(vm.pings.count == 1)
        #expect(vm.pings.first?.text == "Visible ping")
    }

    // MARK: - Ping filtering

    @Test("Expired pings are filtered out from map display")
    func expiredPingsFiltered() async {
        let mockPingService = MockPingService()
        let mockLocationService = MockLocationService()
        let vm = MapViewModel()
        vm.configure(pingService: mockPingService, locationService: mockLocationService)

        vm.startObserving()

        let activePing = Ping(
            creatorId: "user1",
            text: "Active event",
            location: .init(latitude: 46.77, longitude: 23.62),
            geohash: "",
            expiresAt: Date.now.addingTimeInterval(3600),
            status: .active
        )
        let expiredPing = Ping(
            creatorId: "user2",
            text: "Expired event",
            location: .init(latitude: 46.78, longitude: 23.63),
            geohash: "",
            expiresAt: Date.now.addingTimeInterval(-3600),
            status: .active
        )

        mockPingService.simulateUpdate(pings: [activePing, expiredPing])

        // Allow MainActor dispatch
        try? await Task.sleep(for: .milliseconds(50))

        #expect(vm.pings.count == 1)
        #expect(vm.pings.first?.text == "Active event")
    }
}
