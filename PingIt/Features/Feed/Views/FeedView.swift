import SwiftUI

struct FeedView: View {
    @Environment(PingService.self) private var pingService
    @Environment(LocationService.self) private var locationService
    @Environment(BlockService.self) private var blockService
    @Environment(UserService.self) private var userService
    @Environment(AnalyticsService.self) private var analyticsService
    @State private var viewModel = FeedViewModel()
    @State private var selectedPing: Ping?
    @State private var expiryTimer: Timer?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                FeedHeader(viewModel: viewModel, analyticsService: analyticsService)

                FeedContent(
                    viewModel: viewModel,
                    selectedPing: $selectedPing
                )
            }
            .background(Color.pingBackground)
            .navigationBarHidden(true)
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
            .onAppear { startExpiryTimer() }
            .onDisappear { stopExpiryTimer() }
            .onChange(of: blockService.blockedUserIds) { _, _ in
                viewModel.applyFilters()
            }
        }
    }

    private func startExpiryTimer() {
        expiryTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                viewModel.removeExpiredPings()
            }
        }
    }

    private func stopExpiryTimer() {
        expiryTimer?.invalidate()
        expiryTimer = nil
    }
}

// MARK: - Feed Header

private struct FeedHeader: View {
    let viewModel: FeedViewModel
    let analyticsService: AnalyticsService

    var body: some View {
        HStack(alignment: .center) {
            HStack(spacing: 10) {
                Text("Feed")
                    .font(.syne(.extraBold, size: 30))
                    .foregroundStyle(Color.pingTextPrimary)
                    .tracking(-0.5)

                FeedLivePulse()
            }

            Spacer()

            HStack(spacing: 6) {
                ForEach(FeedSortOption.allCases, id: \.self) { option in
                    FeedSortChip(
                        label: option.chipLabel,
                        isSelected: viewModel.sortOption == option
                    ) {
                        viewModel.sortOption = option
                        analyticsService.logEvent(
                            AnalyticsService.EventName.feedSortChanged,
                            parameters: ["sort": option.rawValue]
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }
}

// MARK: - Feed Content

private struct FeedContent: View {
    let viewModel: FeedViewModel
    @Binding var selectedPing: Ping?

    var body: some View {
        if viewModel.isLoading {
            Spacer()
            ProgressView()
                .tint(Color.pingAccent)
            Spacer()
        } else if viewModel.sortedPings.isEmpty {
            ScrollView {
                FeedEmptyState()
            }
            .scrollIndicators(.hidden)
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.sortedPings) { ping in
                        Button {
                            selectedPing = ping
                        } label: {
                            PingFeedCardView(
                                ping: ping,
                                creator: viewModel.creatorCache[ping.creatorId],
                                distanceText: viewModel.distanceText(for: ping),
                                urgency: viewModel.urgency(for: ping),
                                isHot: ping.isHot
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 90)
            }
            .scrollIndicators(.hidden)
        }
    }
}
