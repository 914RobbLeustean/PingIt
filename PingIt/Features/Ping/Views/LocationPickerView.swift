import SwiftUI
import MapKit

struct LocationPickerView: View {
    @Environment(LocationService.self) private var locationService
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedLocation: CLLocationCoordinate2D?
    @Binding var selectedLocationName: String?

    @State private var searchText = ""
    @State private var searchResults: [MKLocalSearchCompletion] = []
    @State private var searchCompleter = LocationSearchCompleter()
    @State private var showMapPicker = false
    @State private var mapPickerCoordinate: CLLocationCoordinate2D?

    var body: some View {
        List {
            Section {
                Button("Use Current Location", systemImage: "location.fill", action: handleUseCurrentLocation)
                    .foregroundStyle(.blue)

                Button("Set Location on Map", systemImage: "map", action: handleShowMapPicker)
                    .foregroundStyle(.blue)
            }

            Section("Search Address") {
                TextField("Search for a place...", text: $searchText)
                    .autocorrectionDisabled()
                    .onChange(of: searchText) { _, newValue in
                        searchCompleter.search(query: newValue)
                    }

                ForEach(searchCompleter.results, id: \.self) { completion in
                    Button(action: { handleSearchResultTap(completion) }) {
                        VStack(alignment: .leading) {
                            Text(completion.title)
                                .font(.body)
                            Text(completion.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Choose Location")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showMapPicker) {
            MapPinPickerView(
                initialCoordinate: locationService.currentLocation?.coordinate ?? Constants.Cluj.center,
                onConfirm: handleMapPinConfirm
            )
        }
    }

    // MARK: - Actions

    private func handleUseCurrentLocation() {
        guard let location = locationService.currentLocation else { return }
        selectedLocation = location.coordinate
        selectedLocationName = "Current Location"
        dismiss()
    }

    private func handleShowMapPicker() {
        showMapPicker = true
    }

    private func handleSearchResultTap(_ completion: MKLocalSearchCompletion) {
        Task {
            guard let coordinate = await resolveSearchResult(completion) else { return }
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

    // MARK: - Search Resolution

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
            result.subtitle.localizedStandardContains("Cluj")
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
    }
}
