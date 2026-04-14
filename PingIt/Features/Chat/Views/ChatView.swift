import SwiftUI

private struct ReportTarget: Identifiable {
    let id = UUID()
    let type: Report.ReportTargetType
    let targetId: String
    let ownerId: String
}

struct ChatView: View {
    @Environment(AuthService.self) private var authService
    @Environment(ChatService.self) private var chatService
    @Environment(PingService.self) private var pingService
    @Environment(ContentModerationService.self) private var contentModerationService
    @Environment(BlockService.self) private var blockService
    @Environment(RateLimitService.self) private var rateLimitService
    @Environment(ReportService.self) private var reportService
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ChatViewModel
    @State private var scrollPosition = ScrollPosition(edge: .bottom)
    @State private var reportTarget: ReportTarget?

    let pingCreatorId: String

    init(chatId: String, pingId: String, pingCreatorId: String) {
        self.pingCreatorId = pingCreatorId
        self._viewModel = State(initialValue: ChatViewModel(chatId: chatId, pingId: pingId))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.messages) { message in
                        MessageBubbleView(
                            message: message,
                            isCurrentUser: message.senderId == viewModel.currentUserId,
                            onReport: {
                                if let id = message.id {
                                    reportTarget = ReportTarget(
                                        type: .message,
                                        targetId: id,
                                        ownerId: message.senderId
                                    )
                                }
                            },
                            onBlock: {
                                Task {
                                    try? await blockService.blockUser(message.senderId)
                                    viewModel.applyBlockFilter()
                                }
                            }
                        )
                    }
                }
                .padding()
            }
            .scrollPosition($scrollPosition)
            .defaultScrollAnchor(.bottom)
            .scrollDismissesKeyboard(.immediately)
            .overlay {
                if let errorMessage = viewModel.errorMessage {
                    ContentUnavailableView(
                        "Chat unavailable",
                        systemImage: "wifi.exclamationmark",
                        description: Text(errorMessage)
                    )
                } else if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.messages.isEmpty {
                    ContentUnavailableView(
                        "No messages yet",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Be the first to say something!")
                    )
                }
            }

            Divider()

            HStack(spacing: 8) {
                TextField("Message...", text: $viewModel.messageText, axis: .vertical)
                    .lineLimit(1...4)
                    .textFieldStyle(.roundedBorder)

                Button("Send", systemImage: "arrow.up.circle.fill", action: handleSend)
                    .labelStyle(.iconOnly)
                    .font(.title2)
                    .disabled(viewModel.canSend == false)
            }
            .padding()
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.configure(authService: authService, chatService: chatService, pingService: pingService, contentModerationService: contentModerationService, blockService: blockService, rateLimitService: rateLimitService)
            viewModel.startObserving()
            viewModel.startObservingPing()
            await viewModel.joinChat()
        }
        .onDisappear {
            viewModel.stopObserving()
            viewModel.stopObservingPing()
            Task {
                await viewModel.leaveChat()
            }
        }
        .onChange(of: viewModel.messages.count) { _, _ in
            scrollToBottom()
        }
        .onChange(of: blockService.blockedUserIds) { _, newValue in
            if newValue.contains(pingCreatorId) {
                dismiss()
            }
        }
        .alert("Ping Unavailable", isPresented: $viewModel.pingUnavailable) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("This ping is no longer available.")
        }
        .sheet(item: $reportTarget) { target in
            ReportView(
                targetType: target.type,
                targetId: target.targetId,
                targetOwnerId: target.ownerId,
                reportService: reportService,
                blockService: blockService
            )
        }
    }

    // MARK: - Actions

    private func handleSend() {
        Task {
            await viewModel.sendMessage()
        }
    }

    private func scrollToBottom() {
        withAnimation {
            scrollPosition.scrollTo(edge: .bottom)
        }
    }
}
