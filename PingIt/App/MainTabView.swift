import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Map", systemImage: "map") {
                MapView()
            }
            Tab("Profile", systemImage: "person.circle") {
                ProfileView()
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}
