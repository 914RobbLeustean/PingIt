import SwiftUI

struct PingDetailView: View {
    @Environment(AuthService.self) private var authService
    @Environment(PingService.self) private var pingService
    @Environment(ChatService.self) private var chatService
    @Environment(UserService.self) private var userService
    @Environment(BlockService.self) private var blockService
    @Environment(ReportService.self) private var reportService
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PingDetailViewModel
    @State private var showDeleteConfirmation = false
    @State private var showBlockConfirmation = false
    @State private var showReportSheet = false
    @State private var navigateToChat = false

    init(ping: Ping) {
        self._viewModel = State(initialValue: PingDetailViewModel(ping: ping))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

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

                HStack {
                    if !viewModel.isCreator {
                        Button(action: { Task { await viewModel.boostPing() } }) {
                            Label(
                                viewModel.hasUserBoosted ? "Boosted" : "Boost",
                                systemImage: viewModel.hasUserBoosted ? "flame.fill" : "flame"
                            )
                        }
                        .disabled(!viewModel.canBoost)
                        .tint(viewModel.hasUserBoosted ? .orange : .primary)
                    }

                    Label(
                        "\(viewModel.ping.boostCount) boost\(viewModel.ping.boostCount == 1 ? "" : "s")",
                        systemImage: "flame"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                if !viewModel.isCreator {
                    VStack(alignment: .leading, spacing: 8) {
                        Divider()

                        Button("Report Ping", systemImage: "exclamationmark.bubble") {
                            showReportSheet = true
                        }
                        .foregroundStyle(.primary)

                        Button("Block User", systemImage: "hand.raised", role: .destructive) {
                            showBlockConfirmation = true
                        }
                    }
                    .padding(.top)
                }

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
                ChatView(chatId: chatId, pingId: viewModel.ping.id ?? "", pingCreatorId: viewModel.ping.creatorId)
            }
        }
        .alert("Delete this ping?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive, action: handleConfirmDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will also delete the associated chat.")
        }
        .alert("Block this user?", isPresented: $showBlockConfirmation) {
            Button("Block", role: .destructive) {
                Task {
                    try? await blockService.blockUser(viewModel.ping.creatorId)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You won't see their pings or messages.")
        }
        .sheet(isPresented: $showReportSheet) {
            if let pingId = viewModel.ping.id {
                ReportView(
                    targetType: .ping,
                    targetId: pingId,
                    targetOwnerId: viewModel.ping.creatorId,
                    targetContent: viewModel.ping.text,
                    reportService: reportService,
                    blockService: blockService,
                    onDidBlock: { dismiss() }
                )
            }
        }
        .alert("Ping Unavailable", isPresented: $viewModel.pingUnavailable) {
            Button("OK") {
                navigateToChat = false
                dismiss()
            }
        } message: {
            Text("This ping is no longer available.")
        }
        .task {
            viewModel.configure(
                authService: authService,
                pingService: pingService,
                chatService: chatService,
                userService: userService
            )
            await viewModel.loadCreator()
            await viewModel.checkBoostStatus()
            viewModel.startCountdownTimer()
            viewModel.startObservingPing()
        }
        .onDisappear(perform: handleDisappear)
        .onChange(of: viewModel.didDeletePing) { _, didDelete in
            if didDelete {
                dismiss()
            }
        }
        .onChange(of: blockService.blockedUserIds) { _, newValue in
            if newValue.contains(viewModel.ping.creatorId) {
                navigateToChat = false
                dismiss()
            }
        }
    }

    // MARK: - Actions

    private func handleDisappear() {
        viewModel.stopCountdownTimer()
        viewModel.stopObservingPing()
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
