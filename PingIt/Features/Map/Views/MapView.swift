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
            ZStack(alignment: .top) {
                mapLayer

                MapTopGradient()
                    .allowsHitTesting(false)

                MapHeader(onRecenter: handleRecenterTap)

                MapAlertStack(
                    alerts: alerts,
                    topPadding: 110
                )
            }
            .ignoresSafeArea(edges: .top)
            .toolbar(.hidden, for: .navigationBar)
            .overlay(alignment: .bottomTrailing) {
                MapCreatePingFAB(action: handleCreatePingTap)
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                    .opacity(sheetPing == nil ? 1 : 0)
                    .animation(.easeOut(duration: 0.2), value: sheetPing == nil)
            }
            .navigationDestination(item: $detailPing) { ping in
                PingDetailView(ping: ping)
            }
            .navigationDestination(item: $chatPing) { ping in
                if let chatId = ping.chatId {
                    ChatView(chatId: chatId, pingId: ping.id ?? "", pingCreatorId: ping.creatorId)
                }
            }
            .sheet(item: $sheetPing) { ping in
                MapPingSheet(
                    ping: ping,
                    creator: sheetCreator,
                    onJoinChat: { handleSheetJoinChat(ping: ping) },
                    onViewDetails: { handleSheetViewDetails(ping: ping) }
                )
            }
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
            .onChange(of: blockService.blockedUserIds) {
                viewModel.applyBlockFilter()
            }
            .onChange(of: viewModel.userLocation?.coordinate.latitude) {
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
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(5))
                    try? await authService.reloadUser()
                    if authService.isEmailVerified { break }
                }
            }
        }
    }

    // MARK: - Map Layer

    private var mapLayer: some View {
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
                    anchor: .center
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
                    Button { zoomToCluster(cluster) } label: {
                        PingClusterAnnotationView(
                            count: cluster.count,
                            containsHotPing: cluster.containsHotPing
                        )
                    }
                    .buttonStyle(.plain)
                }
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .mapControls {}
        .mapControlVisibility(.hidden)
        .onMapCameraChange(frequency: .onEnd) { context in
            viewModel.visibleRegion = context.region
            viewModel.updateClusters()
        }
    }

    // MARK: - Alerts

    private var alerts: [MapAlertItem] {
        var items: [MapAlertItem] = []

        if let errorMessage = viewModel.errorMessage {
            items.append(.init(
                id: "error",
                builder: {
                    AnyView(
                        MapAlertChip(
                            severity: .error,
                            icon: "wifi.exclamationmark",
                            title: "Connection issue",
                            message: errorMessage
                        )
                    )
                }
            ))
        }

        if viewModel.authorizationStatus == .denied
            || viewModel.authorizationStatus == .restricted {
            items.append(.init(
                id: "location-denied",
                builder: {
                    AnyView(
                        MapAlertChip(
                            severity: .warning,
                            icon: "location.slash",
                            title: "Location off",
                            message: "Enable location to see your position.",
                            primaryAction: .init(label: "Settings", handler: handleOpenSettings)
                        )
                    )
                }
            ))
        }

        if !authService.isEmailVerified && showVerificationBanner {
            items.append(.init(
                id: "email",
                builder: {
                    AnyView(
                        EmailVerificationBannerView(
                            onResend: handleResendVerification,
                            onDismiss: { showVerificationBanner = false }
                        )
                    )
                }
            ))
        }

        if viewModel.errorMessage == nil
            && !viewModel.isLoading
            && viewModel.pings.isEmpty {
            items.append(.init(
                id: "empty",
                builder: {
                    AnyView(
                        MapAlertChip(
                            severity: .info,
                            icon: "sparkles",
                            title: "Be the first",
                            message: "No pings nearby. Tap + to create one."
                        )
                    )
                }
            ))
        }

        return items
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

    private func handleRecenterTap() {
        if let location = viewModel.userLocation {
            withAnimation(.easeInOut(duration: 0.6)) {
                cameraPosition = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                ))
            }
        } else if viewModel.authorizationStatus == .notDetermined {
            viewModel.requestLocationPermission()
        }
    }

    // MARK: - Lifecycle

    private func handleReappear() {
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
        sheetPing = ping
        Task {
            sheetCreator = try? await userService.fetchUser(id: ping.creatorId)
        }
    }

    private func handleSheetJoinChat(ping: Ping) {
        sheetPing = nil
        if ping.chatId != nil {
            chatPing = ping
        }
    }

    private func handleSheetViewDetails(ping: Ping) {
        sheetPing = nil
        detailPing = ping
    }
}

// MARK: - Top Gradient

private struct MapTopGradient: View {
    var body: some View {
        LinearGradient(
            colors: [Color.pingBackground.opacity(0.92), .clear],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 160)
        .frame(maxWidth: .infinity, alignment: .top)
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Header (title + recenter)

private struct MapHeader: View {
    let onRecenter: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            Text("Map")
                .font(.syne(.extraBold, size: 28, relativeTo: .largeTitle))
                .foregroundStyle(Color.pingTextPrimary)
                .tracking(-0.5)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            MapRecenterButton(action: onRecenter)
        }
        .padding(.horizontal, 20)
        .padding(.top, 58)
    }
}

private struct MapRecenterButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "location.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.pingAccent)
                .frame(width: 42, height: 42)
                .background(.ultraThinMaterial, in: .circle)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Re-center on my location")
    }
}

// MARK: - FAB

private struct MapCreatePingFAB: View {
    let action: () -> Void

    @State private var glow: CGFloat = 14
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 60, height: 60)
                .background(Color.pingAccent, in: .circle)
                .shadow(color: Color.pingAccent.opacity(0.55), radius: glow)
                .shadow(color: .black.opacity(0.5), radius: 12, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Create Ping")
        .task {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                glow = 24
            }
        }
    }
}

// MARK: - Alert Stack

struct MapAlertItem: Identifiable {
    let id: String
    let builder: () -> AnyView
}

private struct MapAlertStack: View {
    let alerts: [MapAlertItem]
    let topPadding: CGFloat

    var body: some View {
        VStack(spacing: 8) {
            ForEach(alerts) { alert in
                alert.builder()
                    .transition(
                        .move(edge: .top)
                            .combined(with: .opacity)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, topPadding)
        .frame(maxWidth: .infinity, alignment: .top)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: alerts.map(\.id))
    }
}
