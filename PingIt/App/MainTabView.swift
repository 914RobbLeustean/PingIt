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
        .task(id: blockService.currentUserId) {
            guard blockService.currentUserId != nil else { return }
            blockService.startObserving()
        }
    }
}
