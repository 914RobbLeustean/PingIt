import SwiftUI

struct MainTabView: View {
    @Environment(BlockService.self) private var blockService
    @Environment(NavigationRouter.self) private var navigationRouter

    @State private var selectedTab = AppTab.map

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Map", systemImage: "map", value: .map) {
                MapView()
            }
            Tab("Feed", systemImage: "list.bullet", value: .feed) {
                FeedView()
            }
            Tab("Profile", systemImage: "person.circle", value: .profile) {
                ProfileView()
            }
            Tab("Settings", systemImage: "gearshape", value: .settings) {
                SettingsView()
            }
        }
        .tint(Color.pingAccent)
        .task(id: blockService.currentUserId) {
            guard blockService.currentUserId != nil else { return }
            blockService.startObserving()
        }
        .onChange(of: navigationRouter.pendingPingId) {
            if navigationRouter.pendingPingId != nil {
                selectedTab = .map
            }
        }
    }
}

private enum AppTab {
    case map
    case feed
    case profile
    case settings
}
