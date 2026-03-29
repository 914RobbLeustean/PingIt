import SwiftUI

struct PingDetailView: View {
    let ping: Ping
    @Environment(AuthService.self) private var authService
    @Environment(PingService.self) private var pingService
    @Environment(ChatService.self) private var chatService
    @Environment(UserService.self) private var userService
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PingDetailViewModel?
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                CreatorSection(
                    username: viewModel?.creator?.username,
                    countdownText: viewModel?.countdownText ?? ping.expiresAt.countdownDescription
                )

                Text(ping.text)
                    .font(.title3)

                Divider()

                if let createdAt = ping.createdAt {
                    Text("Created \(createdAt.relativeDescription)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ActionSection(
                    chatId: ping.chatId,
                    isCreator: viewModel?.isCreator == true,
                    isDeleting: viewModel?.isDeleting == true,
                    onDelete: handleDeleteTap
                )

                if let errorMessage = viewModel?.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            .padding()
        }
        .navigationTitle("Ping Details")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete this ping?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive, action: handleConfirmDelete)
        } message: {
            Text("This will also delete the associated chat.")
        }
        .onAppear(perform: handleAppear)
        .onDisappear(perform: handleDisappear)
        .onChange(of: viewModel?.didDeletePing) { _, didDelete in
            if didDelete == true {
                dismiss()
            }
        }
    }

    // MARK: - Actions

    private func handleAppear() {
        if viewModel == nil {
            viewModel = PingDetailViewModel(
                ping: ping,
                authService: authService,
                pingService: pingService,
                chatService: chatService,
                userService: userService
            )
        }
        Task {
            await viewModel?.loadCreator()
        }
        viewModel?.startCountdownTimer()
    }

    private func handleDisappear() {
        viewModel?.stopCountdownTimer()
    }

    private func handleDeleteTap() {
        showDeleteConfirmation = true
    }

    private func handleConfirmDelete() {
        Task {
            await viewModel?.deletePing()
        }
    }
}

// MARK: - Subviews

private struct CreatorSection: View {
    let username: String?
    let countdownText: String

    var body: some View {
        HStack {
            Label(username ?? "Loading...", systemImage: "person.circle.fill")
                .font(.headline)
            Spacer()
            Label(countdownText, systemImage: "clock")
                .font(.caption)
                .foregroundStyle(.orange)
        }
    }
}

private struct ActionSection: View {
    let chatId: String?
    let isCreator: Bool
    let isDeleting: Bool
    var onDelete: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if chatId != nil {
                Button("Join Chat", systemImage: "bubble.left.and.bubble.right", action: handleJoinChat)
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            }

            if isCreator {
                Button("Delete Ping", systemImage: "trash", role: .destructive, action: handleDelete)
                    .frame(maxWidth: .infinity)
                    .disabled(isDeleting)
            }
        }
        .padding(.top)
    }

    private func handleJoinChat() {
        // TODO: Navigate to ChatView when implemented
    }

    private func handleDelete() {
        onDelete()
    }
}
