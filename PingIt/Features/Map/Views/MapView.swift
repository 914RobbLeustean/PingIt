import SwiftUI
import MapKit
import FirebaseFirestore

struct MapView: View {
    @Environment(PingService.self) private var pingService
    @Environment(LocationService.self) private var locationService
    @Environment(AuthService.self) private var authService
    @Environment(BlockService.self) private var blockService
    @Environment(NotificationService.self) private var notificationService
    @Environment(NavigationRouter.self) private var navigationRouter
    @Environment(UserService.self) private var userService
    @State private var viewModel = MapViewModel()
    @State private var cameraPosition: MapCameraPosition = .region(Self.clujRegion)
    @State private var hasMovedToUserLocation = false
    @State private var showCreatePing = false
    @State private var selectedPing: Ping?
    @State private var sheetPing: Ping?
    @State private var sheetCreator: User?
    @State private var detailPing: Ping?
    @State private var chatPing: Ping?
    @State private var createdPingLocation: CLLocationCoordinate2D?
    @State private var showVerificationBanner = true
    @State private var isResendingVerification = false
    @State private var showPingUnavailableAlert = false
    @State private var lastUploadedLocation: CLLocation?

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
                            coordinate: viewModel.displayCoordinates[ping.id ?? ""]
                                ?? CLLocationCoordinate2D(
                                    latitude: ping.location.latitude,
                                    longitude: ping.location.longitude
                                ),
                            anchor: .bottom
                        ) {
                            PingAnnotationView(
                                ping: ping,
                                isHot: viewModel.hotPingIds.contains(ping.id ?? "")
                            ) {
                                showPingSheet(ping)
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
                } else if viewModel.pings.isEmpty {
                    VStack {
                        Spacer()
                        Label("No pings nearby. Be the first to create one!", systemImage: "mappin.slash")
                            .font(.callout)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(.rect(cornerRadius: 12))
                            .padding()
                    }
                    .accessibilityElement(children: .combine)
                }

                if viewModel.authorizationStatus == .denied || viewModel.authorizationStatus == .restricted {
                    VStack {
                        HStack {
                            Image(systemName: "location.slash")
                                .foregroundStyle(.red)
                            Text("Location access denied. Enable in Settings to see your position.")
                                .font(.subheadline)
                            Spacer()
                            Button("Open Settings", action: handleOpenSettings)
                                .font(.subheadline)
                                .bold()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(.rect(cornerRadius: 12))
                        .padding(.horizontal)
                        .accessibilityElement(children: .combine)
                        Spacer()
                    }
                    .padding(.top)
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
            .overlay(alignment: .bottomTrailing) {
                Button(action: handleCreatePingTap) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 60, height: 60)
                        .background(Color.pingAccent)
                        .clipShape(.circle)
                        .shadow(color: Color.pingAccent.opacity(0.55), radius: 14)
                        .shadow(color: .black.opacity(0.5), radius: 12, y: 8)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 20)
                .padding(.bottom, 20)
                .accessibilityLabel("Create Ping")
            }
            .navigationDestination(item: $detailPing) { ping in
                PingDetailView(ping: ping)
            }
            .navigationDestination(item: $chatPing) { ping in
                if let chatId = ping.chatId {
                    ChatView(chatId: chatId, pingId: ping.id ?? "", pingCreatorId: ping.creatorId)
                }
            }
            .overlay {
                if let ping = sheetPing {
                    MapPingSheet(
                        ping: ping,
                        creator: sheetCreator,
                        onJoinChat: { handleSheetJoinChat(ping: ping) },
                        onViewDetails: { handleSheetViewDetails(ping: ping) },
                        onDismiss: { dismissPingSheet() }
                    )
                    .transition(.identity)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: sheetPing != nil)
            .sheet(isPresented: $showCreatePing, onDismiss: handleCreatePingDismiss) {
                CreatePingView(createdPingLocation: $createdPingLocation)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
                    .presentationCornerRadius(28)
                    .interactiveDismissDisabled(false)
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
                guard let location = viewModel.userLocation else { return }
                moveToUserLocation(location)
                uploadLocationIfNeeded(location)
            }
            .onChange(of: viewModel.authorizationStatus) { _, newStatus in
                handleAuthorizationChange(newStatus)
            }
            .onChange(of: navigationRouter.pendingPingId) {
                if let pingId = navigationRouter.pendingPingId {
                    navigationRouter.pendingPingId = nil
                    Task { await handleNotificationNavigation(pingId: pingId) }
                }
            }
            .alert("Ping Unavailable", isPresented: $showPingUnavailableAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This ping is no longer available.")
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

    private func handleOpenSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func handleNotificationNavigation(pingId: String) async {
        do {
            let ping = try await pingService.fetchPing(id: pingId)
            if ping.status == .active {
                detailPing = ping
            } else {
                showPingUnavailableAlert = true
            }
        } catch {
            showPingUnavailableAlert = true
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

    private func moveToUserLocation(_ location: CLLocation) {
        guard !hasMovedToUserLocation else { return }
        hasMovedToUserLocation = true
        withAnimation {
            cameraPosition = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            ))
        }
        uploadLocationIfNeeded(location)
    }

    private func uploadLocationIfNeeded(_ location: CLLocation) {
        let threshold: CLLocationDistance = 500
        if let last = lastUploadedLocation, last.distance(from: location) < threshold {
            return
        }
        lastUploadedLocation = location
        Task {
            await notificationService.updateLastKnownLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        }
    }

    private func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            viewModel.startLocationUpdates()
        }
    }

    // MARK: - Ping Sheet

    private func showPingSheet(_ ping: Ping) {
        sheetCreator = nil
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            sheetPing = ping
        }
        Task {
            sheetCreator = try? await userService.fetchUser(id: ping.creatorId)
        }
    }

    private func dismissPingSheet() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            sheetPing = nil
        }
        sheetCreator = nil
    }

    private func handleSheetJoinChat(ping: Ping) {
        dismissPingSheet()
        if ping.chatId != nil {
            chatPing = ping
        }
    }

    private func handleSheetViewDetails(ping: Ping) {
        dismissPingSheet()
        detailPing = ping
    }
}
