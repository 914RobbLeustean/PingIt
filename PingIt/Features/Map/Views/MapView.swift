import SwiftUI
import MapKit
import FirebaseFirestore

struct MapView: View {
    @Environment(PingService.self) private var pingService
    @Environment(LocationService.self) private var locationService
    @State private var viewModel = MapViewModel()
    @State private var cameraPosition: MapCameraPosition = .region(Self.clujRegion)
    @State private var hasMovedToUserLocation = false
    @State private var showCreatePing = false
    @State private var selectedPing: Ping?
    @State private var createdPingLocation: CLLocationCoordinate2D?

    private static let clujRegion = MKCoordinateRegion(
        center: Constants.Cluj.center,
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition) {
                    UserAnnotation()

                    ForEach(viewModel.pings) { ping in
                        Annotation(
                            ping.text,
                            coordinate: CLLocationCoordinate2D(
                                latitude: ping.location.latitude,
                                longitude: ping.location.longitude
                            )
                        ) {
                            PingAnnotationView(ping: ping) {
                                selectedPing = ping
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

                if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        Label(errorMessage, systemImage: "wifi.exclamationmark")
                            .font(.callout)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(.rect(cornerRadius: 12))
                            .padding()
                    }
                } else if viewModel.isLoading {
                    ProgressView()
                }
            }
            .navigationTitle("Map")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Create Ping", systemImage: "plus", action: handleCreatePingTap)
                }
            }
            .navigationDestination(item: $selectedPing) { ping in
                PingDetailView(ping: ping)
            }
            .sheet(isPresented: $showCreatePing, onDismiss: handleCreatePingDismiss) {
                CreatePingView(createdPingLocation: $createdPingLocation)
            }
            .task {
                viewModel.configure(pingService: pingService, locationService: locationService)
            }
            .onAppear(perform: handleAppear)
            .onDisappear(perform: handleDisappear)
            .onChange(of: viewModel.userLocation?.coordinate.latitude) { _, _ in
                moveToUserLocation(viewModel.userLocation)
            }
            .onChange(of: viewModel.authorizationStatus) { _, newStatus in
                handleAuthorizationChange(newStatus)
            }
        }
    }

    // MARK: - Actions

    private func handleCreatePingTap() {
        showCreatePing = true
    }

    private func handleCreatePingDismiss() {
        guard let location = createdPingLocation else { return }
        createdPingLocation = nil
        withAnimation {
            cameraPosition = .region(MKCoordinateRegion(
                center: location,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }

    // MARK: - Lifecycle

    private func handleAppear() {
        viewModel.startObserving()

        if viewModel.authorizationStatus == .notDetermined {
            viewModel.requestLocationPermission()
        }

        if viewModel.authorizationStatus == .authorizedWhenInUse
            || viewModel.authorizationStatus == .authorizedAlways {
            viewModel.startLocationUpdates()
        }
    }

    private func handleDisappear() {
        viewModel.stopObserving()
        viewModel.stopLocationUpdates()
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

    private func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            viewModel.startLocationUpdates()
        }
    }
}
