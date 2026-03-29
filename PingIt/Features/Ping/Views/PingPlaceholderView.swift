import SwiftUI

struct PingPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "Ping Creation",
            systemImage: "mappin.and.ellipse",
            description: Text("Create and view pings here.")
        )
    }
}
