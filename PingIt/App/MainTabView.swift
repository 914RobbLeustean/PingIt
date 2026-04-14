import SwiftUI

struct MainTabView: View {
    @Environment(BlockService.self) private var blockService

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
        .task {
            try? await blockService.loadBlockedUsers()
        }
    }
}
