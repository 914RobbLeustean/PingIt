import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Map", systemImage: "map") {
                MapPlaceholderView()
            }
            Tab("Profile", systemImage: "person.circle") {
                ProfilePlaceholderView()
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsPlaceholderView()
            }
        }
    }
}
