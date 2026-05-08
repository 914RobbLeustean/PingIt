import SwiftUI

struct OnboardingView: View {
    @Environment(UserService.self) private var userService
    @Environment(AnalyticsService.self) private var analyticsService
    @State private var viewModel = OnboardingViewModel()

    let userId: String
    var onComplete: () -> Void

    var body: some View {
        VStack {
            HStack {
                Spacer()
                if viewModel.currentPage < OnboardingViewModel.pageCount - 1 {
                    Button("Skip") {
                        Task { await viewModel.skip() }
                    }
                    .font(.subheadline)
                    .padding()
                }
            }

            TabView(selection: $viewModel.currentPage) {
                OnboardingPageView(
                    systemImage: "map.fill",
                    title: "Discover What's Happening",
                    subtitle: "See real-time pings from students across Cluj-Napoca"
                )
                .tag(0)

                OnboardingPageView(
                    systemImage: "mappin.and.ellipse",
                    title: "Create a Ping",
                    subtitle: "Share study sessions, events, food spots. Set how long it lasts."
                )
                .tag(1)

                OnboardingPageView(
                    systemImage: "bubble.left.and.bubble.right.fill",
                    title: "Join the Conversation",
                    subtitle: "Tap any ping to join its live chat"
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(.easeInOut, value: viewModel.currentPage)

            Button(viewModel.currentPage == OnboardingViewModel.pageCount - 1 ? "Get Started" : "Next") {
                Task { await viewModel.advance() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .onChange(of: viewModel.isComplete) {
            onComplete()
        }
        .task {
            viewModel.configure(
                userService: userService,
                analyticsService: analyticsService,
                userId: userId
            )
        }
    }
}
