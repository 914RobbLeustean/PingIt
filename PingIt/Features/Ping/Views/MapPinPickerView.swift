import SwiftUI
import MapKit

struct MapPinPickerView: View {
    let initialCoordinate: CLLocationCoordinate2D
    var onConfirm: (CLLocationCoordinate2D) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var cameraPosition: MapCameraPosition
    @State private var pinCoordinate: CLLocationCoordinate2D

    init(initialCoordinate: CLLocationCoordinate2D, onConfirm: @escaping (CLLocationCoordinate2D) -> Void) {
        self.initialCoordinate = initialCoordinate
        self.onConfirm = onConfirm
        self._cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: initialCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
        self._pinCoordinate = State(initialValue: initialCoordinate)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition, interactionModes: .all)
                    .mapStyle(.standard)
                    .onMapCameraChange(frequency: .continuous) { context in
                        pinCoordinate = context.camera.centerCoordinate
                    }

                // Center pin overlay — stays fixed at screen center
                Image(systemName: "mappin")
                    .font(.title)
                    .foregroundStyle(.red)
                    .offset(y: -15)
            }
            .navigationTitle("Set Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: handleCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm", action: handleConfirm)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Text("\(pinCoordinate.latitude.formatted(.number.precision(.fractionLength(5)))), \(pinCoordinate.longitude.formatted(.number.precision(.fractionLength(5))))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
    }

    // MARK: - Actions

    private func handleCancel() {
        dismiss()
    }

    private func handleConfirm() {
        onConfirm(pinCoordinate)
    }
}
