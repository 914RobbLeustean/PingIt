import SwiftUI

struct ChatView: View {
    @Environment(AuthService.self) private var authService
    @Environment(ChatService.self) private var chatService
    @Environment(ContentModerationService.self) private var contentModerationService
    @Environment(BlockService.self) private var blockService
    @State private var viewModel: ChatViewModel
    @State private var scrollPosition = ScrollPosition(edge: .bottom)

    init(chatId: String, pingId: String) {
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
                            isCurrentUser: message.senderId == viewModel.currentUserId
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
            viewModel.configure(authService: authService, chatService: chatService, contentModerationService: contentModerationService, blockService: blockService)
            viewModel.startObserving()
            await viewModel.joinChat()
        }
        .onDisappear {
            viewModel.stopObserving()
            Task {
                await viewModel.leaveChat()
            }
        }
        .onChange(of: viewModel.messages.count) { _, _ in
            scrollToBottom()
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
