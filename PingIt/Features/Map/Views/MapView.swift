import SwiftUI
import MapKit
import FirebaseFirestore

struct MapView: View {
    @Environment(PingService.self) private var pingService
    @Environment(LocationService.self) private var locationService
    @Environment(AuthService.self) private var authService
    @Environment(BlockService.self) private var blockService
    @State private var viewModel = MapViewModel()
    @State private var cameraPosition: MapCameraPosition = .region(Self.clujRegion)
    @State private var hasMovedToUserLocation = false
    @State private var showCreatePing = false
    @State private var selectedPing: Ping?
    @State private var createdPingLocation: CLLocationCoordinate2D?
    @State private var showVerificationBanner = true
    @State private var isResendingVerification = false

    private static let clujRegion = MKCoordinateRegion(
        center: Constants.Cluj.center,
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition) {
                    UserAnnotation()

                    ForEach(viewModel.unclusteredPings) { ping in
                        Annotation(
                            ping.text,
                            coordinate: CLLocationCoordinate2D(
                                latitude: ping.location.latitude,
                                longitude: ping.location.longitude
                            ),
                            anchor: .bottom
                        ) {
                            PingAnnotationView(
                                ping: ping,
                                isHot: viewModel.hotPingIds.contains(ping.id ?? "")
                            ) {
                                selectedPing = ping
                            }
                        }
                        .annotationTitles(.hidden)
                    }

                    ForEach(viewModel.clusters) { cluster in
                        Annotation(
                            "\(cluster.count) pings",
                            coordinate: cluster.center
                        ) {
                            PingClusterAnnotationView(
                                count: cluster.count,
                                containsHotPing: cluster.containsHotPing
                            )
                            .onTapGesture(perform: { zoomToCluster(cluster) })
                        }
                        .annotationTitles(.hidden)
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                .mapStyle(.standard)
                .onMapCameraChange(frequency: .onEnd) { context in
                    viewModel.visibleRegion = context.region
                    viewModel.updateClusters()
                }

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

                if !authService.isEmailVerified && showVerificationBanner {
                    VStack {
                        EmailVerificationBannerView(
                            onResend: handleResendVerification,
                            onDismiss: { showVerificationBanner = false }
                        )
                        Spacer()
                    }
                    .padding(.top)
                    .task {
                        while !Task.isCancelled {
                            try? await Task.sleep(for: .seconds(5))
                            try? await authService.reloadUser()
                            if authService.isEmailVerified {
                                break
                            }
                        }
                    }
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
                viewModel.configure(pingService: pingService, locationService: locationService, blockService: blockService)
                handleAppear()
            }
            .onAppear(perform: handleReappear)
            .onDisappear(perform: handleDisappear)
            .onChange(of: blockService.blockedUserIds) { _, _ in
                viewModel.applyBlockFilter()
            }
            .onChange(of: viewModel.userLocation?.coordinate.latitude) { _, _ in
                moveToUserLocation(viewModel.userLocation)
            }
            .onChange(of: viewModel.authorizationStatus) { _, newStatus in
                handleAuthorizationChange(newStatus)
            }
        }
    }

    // MARK: - Actions

    private func handleResendVerification() {
        Task {
            isResendingVerification = true
            defer { isResendingVerification = false }
            try? await authService.sendEmailVerification()
        }
    }

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

    private func handleReappear() {
        // Re-attach listener after returning from another tab (task already configured)
        viewModel.startObserving()
    }

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

    private func zoomToCluster(_ cluster: PingCluster) {
        let lats = cluster.pings.map(\.location.latitude)
        let lons = cluster.pings.map(\.location.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return }

        let latPadding = max((maxLat - minLat) * 0.3, 0.002)
        let lonPadding = max((maxLon - minLon) * 0.3, 0.002)
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) + latPadding,
            longitudeDelta: (maxLon - minLon) + lonPadding
        )

        withAnimation {
            cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
        }
    }

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
