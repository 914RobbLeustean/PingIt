import Testing
import CoreLocation
@testable import PingIt

@Suite("MapViewModel")
@MainActor
struct MapViewModelTests {

    // MARK: - Helpers

    private func makeVM(
        pingService: MockPingService = MockPingService(),
        locationService: MockLocationService = MockLocationService()
    ) -> MapViewModel {
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
}
