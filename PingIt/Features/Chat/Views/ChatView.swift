import SwiftUI
import CoreLocation

private struct ReportTarget: Identifiable {
    let id = UUID()
    let type: Report.ReportTargetType
    let targetId: String
    let ownerId: String
    let content: String?
}

struct ChatView: View {
    @Environment(AuthService.self) private var authService
    @Environment(ChatService.self) private var chatService
    @Environment(PingService.self) private var pingService
    @Environment(UserService.self) private var userService
    @Environment(ContentModerationService.self) private var contentModerationService
    @Environment(BlockService.self) private var blockService
    @Environment(RateLimitService.self) private var rateLimitService
    @Environment(ReportService.self) private var reportService
    @Environment(AnalyticsService.self) private var analyticsService
    @Environment(LocationService.self) private var locationService
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ChatViewModel
    @State private var scrollPosition = ScrollPosition(edge: .bottom)
    @State private var reportTarget: ReportTarget?
    @State private var actionOverlayMessage: ChatMessage?

    let pingCreatorId: String

    init(chatId: String, pingId: String, pingCreatorId: String) {
        self.pingCreatorId = pingCreatorId
        self._viewModel = State(initialValue: ChatViewModel(chatId: chatId, pingId: pingId))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 0) {
            ChatHeader(
                ping: viewModel.currentPing,
                onBack: { dismiss() }
            )

            messageScrollView
        }
        .background(Color.pingBackground)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MessageInputBar(
                text: $viewModel.messageText,
                isSending: viewModel.isSending,
                canSend: viewModel.canSend,
                onSend: handleSend,
                onShareLocation: handleShareLocation
            )
        }
        .task {
            viewModel.configure(
                authService: authService,
                chatService: chatService,
                pingService: pingService,
                userService: userService,
                contentModerationService: contentModerationService,
                blockService: blockService,
                rateLimitService: rateLimitService,
                analyticsService: analyticsService
            )
            await viewModel.loadInitialMessages()
            viewModel.startObservingPing()
            await viewModel.joinChat()
        }
        .onDisappear {
            viewModel.stopObserving()
            viewModel.stopObservingPing()
            // Fire-and-forget; never hop back to MainActor so termination
            // can't be blocked waiting on a Cloud Function call.
            let vm = viewModel
            Task.detached(priority: .background) {
                await withTaskGroup(of: Void.self) { group in
                    group.addTask {
                        await vm.leaveChat()
                    }
                    group.addTask {
                        try? await Task.sleep(for: .seconds(5))
                    }
                    await group.next()
                    group.cancelAll()
                }
            }
        }
        .onChange(of: viewModel.messages.count) {
            scrollToBottom()
        }
        .onChange(of: blockService.blockedUserIds) { _, newValue in
            if newValue.contains(pingCreatorId) {
                dismiss()
            }
        }
        .onChange(of: viewModel.pingUnavailable) { _, unavailable in
            if unavailable {
                dismiss()
            }
        }
        .sheet(item: $reportTarget) { target in
            ReportView(
                targetType: target.type,
                targetId: target.targetId,
                targetOwnerId: target.ownerId,
                targetContent: target.content,
                reportService: reportService,
                blockService: blockService
            )
        }
        .overlay {
            if let message = actionOverlayMessage {
                MessageActionOverlay(
                    isCurrentUser: message.senderId == viewModel.currentUserId,
                    onReaction: { emoji in handleReaction(on: message, emoji: emoji) },
                    onReport: { handleReportTap(for: message) },
                    onBlock: { handleBlockTap(for: message) },
                    onDismiss: { actionOverlayMessage = nil }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.18), value: actionOverlayMessage?.id)
    }

    // MARK: - Message Scroll View

    private var messageScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if viewModel.hasMoreMessages && !viewModel.isLoading {
                    ChatLoadEarlierButton(
                        isLoading: viewModel.isLoadingMore,
                        action: handleLoadMore
                    )
                    .padding(.bottom, 4)
                }

                let entries = buildEntries(from: viewModel.messages)
                ForEach(entries) { entry in
                    switch entry.kind {
                    case .separator(let date):
                        ChatDateSeparator(date: date)
                    case .message(let message):
                        MessageBubbleView(
                            message: message,
                            isCurrentUser: message.senderId == viewModel.currentUserId,
                            sender: viewModel.userCache[message.senderId],
                            showSenderInfo: viewModel.isFirstInGroup(message),
                            isSenderPrivate: viewModel.isSenderPrivate(for: message),
                            currentUserId: viewModel.currentUserId,
                            onLongPress: { actionOverlayMessage = message },
                            onReaction: { emoji in handleReaction(on: message, emoji: emoji) }
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .scrollPosition($scrollPosition)
        .defaultScrollAnchor(.bottom)
        .scrollDismissesKeyboard(.interactively)
        .scrollIndicators(.hidden)
        .overlay {
            messageStateOverlay
        }
    }

    @ViewBuilder
    private var messageStateOverlay: some View {
        if let errorMessage = viewModel.errorMessage {
            ChatStateView(
                icon: "wifi.exclamationmark",
                title: "Chat unavailable",
                message: errorMessage,
                tint: Color.pingHot
            )
        } else if viewModel.isLoading {
            ProgressView()
                .tint(Color.pingAccent)
        } else if viewModel.messages.isEmpty {
            ChatStateView(
                icon: "bubble.left.and.bubble.right",
                title: "No messages yet",
                message: "Be the first to say something!",
                tint: Color.pingTextSecondary
            )
        }
    }

    // MARK: - Entries

    private struct Entry: Identifiable {
        enum Kind {
            case separator(Date)
            case message(ChatMessage)
        }

        let id: String
        let kind: Kind
    }

    private func buildEntries(from messages: [ChatMessage]) -> [Entry] {
        var entries: [Entry] = []
        var lastDay: Date?
        let calendar = Calendar.current

        for message in messages {
            let day = message.createdAt.map { calendar.startOfDay(for: $0) }
            if let day, day != lastDay {
                entries.append(.init(id: "sep-\(day.timeIntervalSinceReferenceDate)", kind: .separator(day)))
                lastDay = day
            }
            let id = message.id ?? UUID().uuidString
            entries.append(.init(id: id, kind: .message(message)))
        }
        return entries
    }

    // MARK: - Actions

    private func handleReportTap(for message: ChatMessage) {
        guard let id = message.id else { return }
        reportTarget = ReportTarget(
            type: .message,
            targetId: id,
            ownerId: message.senderId,
            content: message.text
        )
    }

    private func handleBlockTap(for message: ChatMessage) {
        Task {
            try? await blockService.blockUser(message.senderId)
            viewModel.applyBlockFilter()
        }
    }

    private func handleReaction(on message: ChatMessage, emoji: String) {
        guard let messageId = message.id else { return }
        Task {
            await viewModel.toggleReaction(on: messageId, emoji: emoji)
        }
    }

    private func handleShareLocation() {
        guard let location = locationService.currentLocation else {
            viewModel.setError(PingItError.locationUnavailable.localizedDescription)
            return
        }
        Task {
            let geocoder = CLGeocoder()
            let locationName: String? = try? await {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                guard let placemark = placemarks.first else { return nil }
                return [placemark.name, placemark.locality]
                    .compactMap { $0 }
                    .joined(separator: ", ")
            }()
            await viewModel.sendLocationMessage(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                locationName: locationName
            )
        }
    }

    private func handleSend() {
        Task { await viewModel.sendMessage() }
    }

    private func handleLoadMore() {
        Task { await viewModel.loadMoreMessages() }
    }

    private func scrollToBottom() {
        withAnimation {
            scrollPosition.scrollTo(edge: .bottom)
        }
    }
}

// MARK: - Load Earlier Button

private struct ChatLoadEarlierButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.mini)
                        .tint(Color.pingTextSecondary)
                } else {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Load earlier messages")
                        .font(.dmSans(.medium, size: 12, relativeTo: .caption))
                }
            }
            .foregroundStyle(Color.pingTextSecondary)
            .padding(.horizontal, 14)
            .frame(height: 32)
            .background(Color.pingSurface, in: .capsule)
            .overlay(
                Capsule().strokeBorder(Color.pingBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

// MARK: - State View

private struct ChatStateView: View {
    let icon: String
    let title: String
    let message: String
    let tint: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(tint)

            Text(title)
                .font(.syne(.bold, size: 18, relativeTo: .headline))
                .foregroundStyle(Color.pingTextPrimary)

            Text(message)
                .font(.dmSans(.regular, size: 13, relativeTo: .footnote))
                .foregroundStyle(Color.pingTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(24)
        .accessibilityElement(children: .combine)
    }
}
