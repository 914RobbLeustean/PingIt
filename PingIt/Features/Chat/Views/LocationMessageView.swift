import SwiftUI
import MapKit

struct LocationMessageView: View {
    let latitude: Double
    let longitude: Double
    let locationName: String?
    let isCurrentUser: Bool

    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var body: some View {
        Button {
            openInMaps()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                ))) {
                    Marker(locationName ?? "Shared location", coordinate: coordinate)
                }
                .frame(width: 200, height: 150)
                .clipShape(.rect(cornerRadius: 12))
                .allowsHitTesting(false)

                if let locationName {
                    Text(locationName)
                        .font(.caption)
                        .foregroundStyle(isCurrentUser ? .white : .primary)
                }
            }
            .padding(4)
            .background(isCurrentUser ? Color.accentColor : Color(.systemGray5))
            .clipShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Location: \(locationName ?? "Shared location"). Double tap to open in Maps.")
    }

    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = locationName ?? "Shared location"
        mapItem.openInMaps()
    }
}
