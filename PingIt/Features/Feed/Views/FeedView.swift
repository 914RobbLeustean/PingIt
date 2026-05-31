import SwiftUI

struct FeedView: View {
    @Environment(PingService.self) private var pingService
    @Environment(LocationService.self) private var locationService
    @Environment(BlockService.self) private var blockService
    @Environment(UserService.self) private var userService
    @Environment(AnalyticsService.self) private var analyticsService
    @State private var viewModel = FeedViewModel()
    @State private var selectedPing: Ping?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.sortedPings) { ping in
                        Button {
                            selectedPing = ping
                        } label: {
                            PingFeedCardView(
                                ping: ping,
                                creator: viewModel.creatorCache[ping.creatorId],
                                distanceText: viewModel.distanceText(for: ping),
                                isHot: ping.isHot
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.sortedPings.isEmpty {
                    ContentUnavailableView(
                        "No Pings",
                        systemImage: "mappin.slash",
                        description: Text("There are no active pings right now.")
                    )
                }
            }
            .navigationTitle("Feed")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(FeedSortOption.allCases, id: \.self) { option in
                            Button {
                                viewModel.sortOption = option
                                analyticsService.logEvent(AnalyticsService.EventName.feedSortChanged, parameters: ["sort": option.rawValue])
                            } label: {
                                if viewModel.sortOption == option {
                                    Label(option.displayName, systemImage: "checkmark")
                                } else {
                                    Text(option.displayName)
                                }
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
            .navigationDestination(item: $selectedPing) { ping in
                PingDetailView(ping: ping)
            }
            .task {
                viewModel.configure(
                    pingService: pingService,
                    locationService: locationService,
                    blockService: blockService,
                    userService: userService,
                    analyticsService: analyticsService
                )
                viewModel.startObserving()
                analyticsService.logEvent(AnalyticsService.EventName.feedViewed, parameters: nil)
            }
            .onChange(of: blockService.blockedUserIds) { _, _ in
                viewModel.applyFilters()
            }
        }
    }
}
