import SwiftUI

struct PingDetailView: View {
    @Environment(AuthService.self) private var authService
    @Environment(PingService.self) private var pingService
    @Environment(ChatService.self) private var chatService
    @Environment(UserService.self) private var userService
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PingDetailViewModel
    @State private var showDeleteConfirmation = false
    @State private var navigateToChat = false

    init(ping: Ping) {
        self._viewModel = State(initialValue: PingDetailViewModel(ping: ping))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                PingDetailCreatorSection(
                    username: viewModel.creator?.username,
                    profileImageUrl: viewModel.creator?.profileImageUrl,
                    countdownText: viewModel.countdownText
                )

                Text(viewModel.ping.text)
                    .font(.title3)

                Divider()

                if let createdAt = viewModel.ping.createdAt {
                    Text("Created \(createdAt.relativeDescription)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                PingDetailActionSection(
                    chatId: viewModel.ping.chatId,
                    isCreator: viewModel.isCreator,
                    isDeleting: viewModel.isDeleting,
                    onJoinChat: handleJoinChat,
                    onDelete: handleDeleteTap
                )

                if let errorMessage = viewModel.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            .padding()
        }
        .navigationTitle("Ping Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToChat) {
            if let chatId = viewModel.ping.chatId {
                ChatView(chatId: chatId, pingId: viewModel.ping.id ?? "")
            }
        }
        .alert("Delete this ping?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive, action: handleConfirmDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will also delete the associated chat.")
        }
        .task {
            viewModel.configure(
                authService: authService,
                pingService: pingService,
                chatService: chatService,
                userService: userService
            )
            await viewModel.loadCreator()
            viewModel.startCountdownTimer()
        }
        .onDisappear(perform: handleDisappear)
        .onChange(of: viewModel.didDeletePing) { _, didDelete in
            if didDelete {
                dismiss()
            }
        }
    }

    // MARK: - Actions

    private func handleDisappear() {
        viewModel.stopCountdownTimer()
    }

    private func handleJoinChat() {
        navigateToChat = true
    }

    private func handleDeleteTap() {
        showDeleteConfirmation = true
    }

    private func handleConfirmDelete() {
        Task {
            await viewModel.deletePing()
        }
    }
}
