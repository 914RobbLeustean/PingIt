import Testing
import CoreLocation
import MapKit
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

    // MARK: - Recap toggle + zoom gating

    /// A recap with photoCount > 0 is visible to anyone (isVisibleOnMap).
    private func makeVisibleRecap() -> PingRecap {
        PingRecap(
            id: "recap1",
            pingId: "recap1",
            title: "Last night",
            category: nil,
            location: .init(latitude: 46.77, longitude: 23.62),
            attendeeIds: ["someone"],
            photoCount: 3,
            expiresAt: Date.now.addingTimeInterval(-3600),
            recapWindowClosesAt: Date.now.addingTimeInterval(3600),
            ghostExpiresAt: Date.now.addingTimeInterval(24 * 3600)
        )
    }

    private let closeRegion = MKCoordinateRegion(
        center: .init(latitude: 46.77, longitude: 23.62),
        span: .init(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    private let farRegion = MKCoordinateRegion(
        center: .init(latitude: 46.77, longitude: 23.62),
        span: .init(latitudeDelta: 0.2, longitudeDelta: 0.2)
    )

    @Test("Recaps show when enabled and zoomed in close")
    func recapsVisibleWhenEnabledAndZoomedIn() async {
        let recapService = MockPingRecapService()
        let vm = MapViewModel()
        vm.configure(pingService: MockPingService(), locationService: MockLocationService(), recapService: recapService)
        vm.startObserving()
        vm.visibleRegion = closeRegion
        recapService.activeRecapsCallback?(.success([makeVisibleRecap()]))
        try? await Task.sleep(for: .milliseconds(50))

        #expect(vm.isRecapsEnabled == true)   // on by default
        #expect(vm.recaps.count == 1)
    }

    @Test("Recaps hidden when zoomed out past threshold")
    func recapsHiddenWhenZoomedOut() async {
        let recapService = MockPingRecapService()
        let vm = MapViewModel()
        vm.configure(pingService: MockPingService(), locationService: MockLocationService(), recapService: recapService)
        vm.startObserving()
        vm.visibleRegion = farRegion
        recapService.activeRecapsCallback?(.success([makeVisibleRecap()]))
        try? await Task.sleep(for: .milliseconds(50))

        #expect(vm.recaps.isEmpty)
    }

    @Test("Toggling recaps off hides markers even when zoomed in")
    func togglingRecapsOffHidesMarkers() async {
        let recapService = MockPingRecapService()
        let vm = MapViewModel()
        vm.configure(pingService: MockPingService(), locationService: MockLocationService(), recapService: recapService)
        vm.startObserving()
        vm.visibleRegion = closeRegion
        recapService.activeRecapsCallback?(.success([makeVisibleRecap()]))
        try? await Task.sleep(for: .milliseconds(50))
        #expect(vm.recaps.count == 1)

        vm.toggleRecaps()
        #expect(vm.isRecapsEnabled == false)
        #expect(vm.recaps.isEmpty)

        vm.toggleRecaps()
        #expect(vm.isRecapsEnabled == true)
        #expect(vm.recaps.count == 1)
    }
}
