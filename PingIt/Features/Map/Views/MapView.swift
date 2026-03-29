import SwiftUI
import MapKit
import FirebaseFirestore

struct MapView: View {
    @Environment(PingService.self) private var pingService
    @Environment(LocationService.self) private var locationService
    @State private var viewModel: MapViewModel?
    @State private var cameraPosition: MapCameraPosition = .region(Self.clujRegion)
    @State private var hasMovedToUserLocation = false

    private static let clujRegion = MKCoordinateRegion(
        center: Constants.Cluj.center,
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )

    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition) {
                UserAnnotation()

                if let viewModel {
                    ForEach(viewModel.pings) { ping in
                        Annotation(
                            ping.text,
                            coordinate: CLLocationCoordinate2D(
                                latitude: ping.location.latitude,
                                longitude: ping.location.longitude
                            )
                        ) {
                            PingAnnotationView(ping: ping) {
                                // TODO: Navigate to ping detail
                            }
                        }
                    }
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .mapStyle(.standard)
            .navigationTitle("Map")
            .onAppear(perform: handleAppear)
            .onDisappear(perform: handleDisappear)
            .onChange(of: viewModel?.userLocation?.coordinate.latitude) { _, _ in
                moveToUserLocation(viewModel?.userLocation)
            }
            .onChange(of: viewModel?.authorizationStatus) { _, newStatus in
                handleAuthorizationChange(newStatus)
            }
        }
    }

    // MARK: - Lifecycle

    private func handleAppear() {
        if viewModel == nil {
            viewModel = MapViewModel(pingService: pingService, locationService: locationService)
        }
        viewModel?.startObserving()

        if viewModel?.authorizationStatus == .notDetermined {
            viewModel?.requestLocationPermission()
        }

        if viewModel?.authorizationStatus == .authorizedWhenInUse
            || viewModel?.authorizationStatus == .authorizedAlways {
            viewModel?.startLocationUpdates()
        }
    }

    private func handleDisappear() {
        viewModel?.stopObserving()
        viewModel?.stopLocationUpdates()
    }

    // MARK: - Camera

    private func moveToUserLocation(_ location: CLLocation?) {
        guard !hasMovedToUserLocation, let location else { return }
        hasMovedToUserLocation = true
        withAnimation {
            cameraPosition = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            ))
        }
    }

    private func handleAuthorizationChange(_ status: CLAuthorizationStatus?) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            viewModel?.startLocationUpdates()
        }
    }
}
