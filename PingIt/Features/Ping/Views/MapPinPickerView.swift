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
        ZStack {
            Map(position: $cameraPosition, interactionModes: .all)
                .mapStyle(.standard(elevation: .flat))
                .onMapCameraChange(frequency: .continuous) { context in
                    pinCoordinate = context.camera.centerCoordinate
                }

            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.pingAccent)
                .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
                .offset(y: -18)

            VStack {
                Spacer()

                VStack(spacing: 12) {
                    Text("\(pinCoordinate.latitude.formatted(.number.precision(.fractionLength(5)))), \(pinCoordinate.longitude.formatted(.number.precision(.fractionLength(5))))")
                        .font(.dmSans(.regular, size: 12, relativeTo: .caption))
                        .foregroundStyle(Color.pingTextSecondary)

                    HStack(spacing: 12) {
                        Button("Cancel", action: handleCancel)
                            .font(.dmSans(.semiBold, size: 15, relativeTo: .body))
                            .foregroundStyle(Color.pingTextPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.pingSurfaceElevated)
                            .clipShape(.capsule)
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.pingBorder, lineWidth: 1)
                            )

                        Button("Confirm", action: handleConfirm)
                            .font(.syne(.bold, size: 15, relativeTo: .body))
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.pingAccent)
                            .clipShape(.capsule)
                            .shadow(color: Color.pingAccent.opacity(0.35), radius: 12, y: 4)
                    }
                }
                .padding(20)
                .background(Color.pingSurface)
                .clipShape(.rect(cornerRadii: .init(topLeading: 24, topTrailing: 24)))
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
    }

    private func handleCancel() {
        dismiss()
    }

    private func handleConfirm() {
        onConfirm(pinCoordinate)
    }
}
