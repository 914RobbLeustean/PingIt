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

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 36, height: 4)
                    .padding(.top, 14)
                    .padding(.bottom, 16)

                HStack {
                    Text("Choose Location")
                        .font(.syne(.extraBold, size: 22, relativeTo: .title2))
                        .foregroundStyle(Color.pingTextPrimary)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
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
                    .accessibilityLabel("Dismiss")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }

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
        .sheet(isPresented: $showMapPicker) {
            MapPinPickerView(
                initialCoordinate: locationService.currentLocation?.coordinate ?? Constants.Cluj.center,
                onConfirm: handleMapPinConfirm
            )
        }
    }

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

    private func handleMapPinConfirm(_ coordinate: CLLocationCoordinate2D) {
        selectedLocation = coordinate
        selectedLocationName = "Pinned Location"
        showMapPicker = false
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
