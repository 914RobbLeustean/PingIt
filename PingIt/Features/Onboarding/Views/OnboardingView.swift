import SwiftUI

struct OnboardingView: View {
    @Environment(UserService.self) private var userService
    @Environment(AnalyticsService.self) private var analyticsService
    @State private var viewModel = OnboardingViewModel()

    let userId: String
    var onComplete: () -> Void

    private static let pages: [OnboardingPageContent] = [
        .init(
            emoji: "🗺️",
            accentSymbol: "sparkles",
            title: "Discover what's happening",
            subtitle: "Real-time pings from students across Cluj-Napoca. See who's hanging out where."
        ),
        .init(
            emoji: "📍",
            accentSymbol: "plus",
            title: "Create a Ping",
            subtitle: "Share study sessions, events, food spots. Pick a category and set how long it lasts."
        ),
        .init(
            emoji: "💬",
            accentSymbol: "bolt.fill",
            title: "Join the conversation",
            subtitle: "Tap any ping to drop into its live chat. Meet people who are actually nearby."
        )
    ]

    var body: some View {
        ZStack {
            Color.pingBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                OnboardingTopBar(
                    isLastPage: viewModel.currentPage == OnboardingViewModel.pageCount - 1,
                    onSkip: handleSkip
                )
                .padding(.top, 12)

                TabView(selection: $viewModel.currentPage) {
                    ForEach(Self.pages.indices, id: \.self) { index in
                        OnboardingPageView(
                            emoji: Self.pages[index].emoji,
                            accentSymbol: Self.pages[index].accentSymbol,
                            title: Self.pages[index].title,
                            subtitle: Self.pages[index].subtitle
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentPage)

                OnboardingPageIndicator(
                    count: OnboardingViewModel.pageCount,
                    selected: viewModel.currentPage
                )
                .padding(.bottom, 24)

                OnboardingPrimaryButton(
                    isLastPage: viewModel.currentPage == OnboardingViewModel.pageCount - 1,
                    action: handleAdvance
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: viewModel.isComplete) {
            if viewModel.isComplete { onComplete() }
        }
        .task {
            viewModel.configure(
                userService: userService,
                analyticsService: analyticsService,
                userId: userId
            )
        }
    }

    private func handleAdvance() {
        Task { await viewModel.advance() }
    }

    private func handleSkip() {
        Task { await viewModel.skip() }
    }
}

// MARK: - Page Content

private struct OnboardingPageContent {
    let emoji: String
    let accentSymbol: String
    let title: String
    let subtitle: String
}

// MARK: - Top Bar (Skip)

private struct OnboardingTopBar: View {
    let isLastPage: Bool
    let onSkip: () -> Void

    var body: some View {
        HStack {
            Spacer()

            if !isLastPage {
                Button(action: onSkip) {
                    Text("Skip")
                        .font(.dmSans(.semiBold, size: 14, relativeTo: .body))
                        .foregroundStyle(Color.pingTextSecondary)
                        .padding(.horizontal, 16)
                        .frame(height: 36)
                        .background(Color.pingSurface, in: .capsule)
                        .overlay(
                            Capsule().strokeBorder(Color.pingBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Skip onboarding")
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 44)
    }
}

// MARK: - Page Indicator

private struct OnboardingPageIndicator: View {
    let count: Int
    let selected: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == selected ? Color.pingAccent : Color.pingTextSecondary.opacity(0.35))
                    .frame(width: index == selected ? 28 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selected)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(selected + 1) of \(count)")
    }
}

// MARK: - Primary Button

private struct OnboardingPrimaryButton: View {
    let isLastPage: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(isLastPage ? "Get Started" : "Next")
                    .font(.syne(.extraBold, size: 15))
                    .tracking(-0.3)
                if !isLastPage {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.pingAccent, in: .capsule)
            .shadow(color: Color.pingAccent.opacity(0.4), radius: 16, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isLastPage ? "Get started" : "Next page")
    }
}
