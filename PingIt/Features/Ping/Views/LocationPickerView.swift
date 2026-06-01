import SwiftUI
import MapKit

struct LocationPickerView: View {
    @Environment(LocationService.self) private var locationService
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedLocation: CLLocationCoordinate2D?
    @Binding var selectedLocationName: String?

    @State private var searchText = ""
    @State private var searchCompleter = LocationSearchCompleter()
    @State private var showMapPicker = false
    @State private var showSearch = false
    @State private var errorMessage: String?
    @State private var mapCameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: Constants.Cluj.center,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )
    @State private var mapPinCoordinate = Constants.Cluj.center

    var body: some View {
        if showMapPicker {
            mapPickerContent
        } else {
            optionsContent
        }
    }

    // MARK: - Options View

    private var optionsContent: some View {
        VStack(spacing: 0) {
            locationPickerHeader(title: "Choose Location", onLeading: { dismiss() })

            ScrollView {
                VStack(spacing: 16) {
                    if let errorMessage {
                        CreatePingErrorBanner(message: errorMessage)
                    }

                    VStack(spacing: 0) {
                        LocationOptionRow(
                            icon: "location.fill",
                            label: "Use Current Location",
                            action: handleUseCurrentLocation
                        )

                        SettingsRowDivider()

                        LocationOptionRow(
                            icon: "map.fill",
                            label: "Set Location on Map",
                            action: handleShowMapPicker
                        )

                        SettingsRowDivider()

                        LocationOptionRow(
                            icon: "magnifyingglass",
                            label: "Search Address",
                            action: { showSearch.toggle() }
                        )
                    }
                    .background(Color.pingSurfaceElevated)
                    .clipShape(.rect(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.pingBorder, lineWidth: 1)
                    )
                    .padding(.horizontal, 20)

                    if showSearch {
                        searchSection
                    }
                }
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color.pingSurface)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
    }

    // MARK: - Inline Map Picker

    private var mapPickerContent: some View {
        ZStack {
            Map(position: $mapCameraPosition, interactionModes: .all)
                .mapStyle(.standard(elevation: .flat))
                .onMapCameraChange(frequency: .continuous) { context in
                    mapPinCoordinate = context.camera.centerCoordinate
                }
                .ignoresSafeArea(edges: .bottom)

            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.pingAccent)
                .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
                .offset(y: -18)

            VStack {
                locationPickerHeader(title: "Set Location", onLeading: { showMapPicker = false })
                    .background(
                        LinearGradient(
                            colors: [Color.pingSurface, Color.pingSurface.opacity(0.6), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Spacer()

                VStack(spacing: 12) {
                    Text("\(mapPinCoordinate.latitude.formatted(.number.precision(.fractionLength(5)))), \(mapPinCoordinate.longitude.formatted(.number.precision(.fractionLength(5))))")
                        .font(.dmSans(.regular, size: 12, relativeTo: .caption))
                        .foregroundStyle(Color.pingTextSecondary)

                    Button("Confirm Location", action: handleMapPinConfirm)
                        .font(.syne(.bold, size: 15, relativeTo: .body))
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.pingAccent)
                        .clipShape(.capsule)
                        .shadow(color: Color.pingAccent.opacity(0.35), radius: 12, y: 4)
                }
                .padding(20)
                .background(Color.pingSurface)
                .clipShape(.rect(cornerRadii: .init(topLeading: 24, topTrailing: 24)))
            }
        }
        .background(Color.pingSurface)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
        .transition(.move(edge: .trailing))
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: showMapPicker)
    }

    // MARK: - Shared Header

    private func locationPickerHeader(title: String, onLeading: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.12))
                .frame(width: 36, height: 4)
                .padding(.top, 14)
                .padding(.bottom, 16)

            HStack {
                Button(action: onLeading) {
                    Image(systemName: showMapPicker ? "chevron.left" : "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.pingTextSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color.pingSurfaceElevated)
                        .clipShape(.circle)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.pingBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(showMapPicker ? "Back" : "Dismiss")

                Text(title)
                    .font(.syne(.extraBold, size: 22, relativeTo: .title2))
                    .foregroundStyle(Color.pingTextPrimary)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Search Section

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.pingTextSecondary)

                TextField("Search for a place...", text: $searchText)
                    .font(.dmSans(.regular, size: 14, relativeTo: .body))
                    .foregroundStyle(Color.pingTextPrimary)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(Color.pingSurfaceElevated)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.pingBorder, lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .onChange(of: searchText) { _, newValue in
                searchCompleter.search(query: newValue)
            }

            if !searchCompleter.results.isEmpty {
                VStack(spacing: 0) {
                    ForEach(searchCompleter.results, id: \.self) { completion in
                        Button(action: { handleSearchResultTap(completion) }) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(completion.title)
                                    .font(.dmSans(.medium, size: 14, relativeTo: .body))
                                    .foregroundStyle(Color.pingTextPrimary)
                                Text(completion.subtitle)
                                    .font(.dmSans(.regular, size: 12, relativeTo: .caption))
                                    .foregroundStyle(Color.pingTextSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .frame(minHeight: 48)
                            .contentShape(.rect)
                        }
                        .buttonStyle(SettingsRowButtonStyle())
                    }
                }
                .background(Color.pingSurfaceElevated)
                .clipShape(.rect(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.pingBorder, lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showSearch)
    }

    // MARK: - Actions

    private func handleUseCurrentLocation() {
        guard let location = locationService.currentLocation else {
            errorMessage = PingItError.locationUnavailable.localizedDescription
            return
        }
        selectedLocation = location.coordinate
        selectedLocationName = "Current Location"
        dismiss()
    }

    private func handleShowMapPicker() {
        let center = locationService.currentLocation?.coordinate ?? Constants.Cluj.center
        mapCameraPosition = .region(MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
        mapPinCoordinate = center
        showMapPicker = true
    }

    private func handleSearchResultTap(_ completion: MKLocalSearchCompletion) {
        Task {
            guard let coordinate = await resolveSearchResult(completion) else {
                errorMessage = "Could not find location. Please try again."
                return
            }
            errorMessage = nil
            selectedLocation = coordinate
            selectedLocationName = completion.title
            dismiss()
        }
    }

    private func handleMapPinConfirm() {
        selectedLocation = mapPinCoordinate
        selectedLocationName = "Pinned Location"
        dismiss()
    }

    private func resolveSearchResult(_ completion: MKLocalSearchCompletion) async -> CLLocationCoordinate2D? {
        let request = MKLocalSearch.Request(completion: completion)
        request.region = MKCoordinateRegion(
            center: Constants.Cluj.center,
            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        )
        do {
            let response = try await MKLocalSearch(request: request).start()
            return response.mapItems.first?.placemark.coordinate
        } catch {
            return nil
        }
    }
}

// MARK: - Location Search Completer

@Observable
final class LocationSearchCompleter: NSObject {
    private(set) var results: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
        completer.region = MKCoordinateRegion(
            center: Constants.Cluj.center,
            span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
        )
        completer.regionPriority = .required
    }

    func search(query: String) {
        guard !query.isEmpty else {
            results = []
            return
        }
        completer.queryFragment = query
    }
}

extension LocationSearchCompleter: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results.filter { result in
            let haystack = "\(result.title) \(result.subtitle)"
            return haystack.localizedStandardContains("Cluj")
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
    }
}

// MARK: - Location Option Row

struct LocationOptionRow: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.pingAccent)
                    .frame(width: 24)

                Text(label)
                    .font(.dmSans(.medium, size: 15, relativeTo: .body))
                    .foregroundStyle(Color.pingTextPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.pingTextSecondary)
            }
            .padding(.horizontal, 18)
            .frame(minHeight: 52)
            .contentShape(.rect)
        }
        .buttonStyle(SettingsRowButtonStyle())
    }
}
