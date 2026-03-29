import SwiftUI

struct MapPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Map Coming Soon",
                systemImage: "map",
                description: Text("Real-time ping map will appear here.")
            )
            .navigationTitle("Map")
        }
    }
}
