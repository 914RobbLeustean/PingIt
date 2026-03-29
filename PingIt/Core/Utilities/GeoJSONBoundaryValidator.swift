import CoreLocation

/// Validates whether a coordinate falls within the Cluj-Napoca administrative boundary
/// using the GeoJSON polygon from the app bundle and a ray casting algorithm.
enum GeoJSONBoundaryValidator {
    private static let polygon: [CLLocationCoordinate2D] = loadPolygon()

    // Bounding box for fast rejection (from ClujNapoca.geojson bbox)
    private static let minLatitude = 46.6899
    private static let maxLatitude = 46.8619
    private static let minLongitude = 23.4992
    private static let maxLongitude = 23.7184

    /// Returns true if the coordinate falls within the Cluj-Napoca administrative boundary.
    static func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        // Fast bounding box rejection
        guard coordinate.latitude >= minLatitude,
              coordinate.latitude <= maxLatitude,
              coordinate.longitude >= minLongitude,
              coordinate.longitude <= maxLongitude else {
            return false
        }

        return isPointInPolygon(coordinate, polygon: polygon)
    }

    // MARK: - Ray Casting Algorithm

    /// Determines if a point is inside a polygon using the ray casting (even-odd) algorithm.
    /// Casts a horizontal ray to the right from the test point and counts edge crossings.
    private static func isPointInPolygon(
        _ point: CLLocationCoordinate2D,
        polygon: [CLLocationCoordinate2D]
    ) -> Bool {
        let count = polygon.count
        guard count > 2 else { return false }

        var inside = false
        var j = count - 1

        for i in 0..<count {
            let vi = polygon[i]
            let vj = polygon[j]

            // Check if edge crosses the horizontal ray from point
            if (vi.longitude > point.longitude) != (vj.longitude > point.longitude) {
                let intersectLatitude = vj.latitude
                    + (point.longitude - vj.longitude)
                    / (vi.longitude - vj.longitude)
                    * (vi.latitude - vj.latitude)

                if point.latitude < intersectLatitude {
                    inside.toggle()
                }
            }

            j = i
        }

        return inside
    }

    // MARK: - GeoJSON Loading

    private static func loadPolygon() -> [CLLocationCoordinate2D] {
        guard let url = Bundle.main.url(forResource: "ClujNapoca", withExtension: "geojson"),
              let data = try? Data(contentsOf: url),
              let collection = try? JSONDecoder().decode(GeoJSONFeatureCollection.self, from: data),
              let feature = collection.features.first,
              let ring = feature.geometry.coordinates.first else {
            assertionFailure("Failed to load ClujNapoca.geojson from bundle")
            return []
        }

        return ring.map { pair in
            // GeoJSON uses [longitude, latitude] order
            CLLocationCoordinate2D(latitude: pair[1], longitude: pair[0])
        }
    }
}

// MARK: - GeoJSON Codable Types

private struct GeoJSONFeatureCollection: Decodable {
    let features: [GeoJSONFeature]
}

private struct GeoJSONFeature: Decodable {
    let geometry: GeoJSONGeometry
}

private struct GeoJSONGeometry: Decodable {
    let coordinates: [[[Double]]]
}
