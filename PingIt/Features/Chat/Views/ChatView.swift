import SwiftUI

struct ChatView: View {
    @Environment(AuthService.self) private var authService
    @Environment(ChatService.self) private var chatService
    @State private var viewModel: ChatViewModel

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
            .defaultScrollAnchor(.bottom)
            .overlay {
                if viewModel.isLoading {
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
            viewModel.configure(authService: authService, chatService: chatService)
            viewModel.startObserving()
            await viewModel.joinChat()
        }
        .onDisappear {
            viewModel.stopObserving()
        }
    }

    // MARK: - Actions

    private func handleSend() {
        Task {
            await viewModel.sendMessage()
        }
    }
}
