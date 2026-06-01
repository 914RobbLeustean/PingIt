import SwiftUI

struct PingDetailView: View {
    @Environment(AuthService.self) private var authService
    @Environment(PingService.self) private var pingService
    @Environment(ChatService.self) private var chatService
    @Environment(UserService.self) private var userService
    @Environment(BlockService.self) private var blockService
    @Environment(ReportService.self) private var reportService
    @Environment(AnalyticsService.self) private var analyticsService
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

        VStack(spacing: 0) {
            DetailNavBar(onBack: { dismiss() })

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    DetailAuthorTimerRow(
                        creator: viewModel.shouldHideCreatorIdentity ? nil : viewModel.creator,
                        createdAt: viewModel.ping.createdAt,
                        expiresAt: viewModel.ping.expiresAt,
                        urgency: viewModel.urgency,
                        countdownText: viewModel.countdownText,
                        hideIdentity: viewModel.shouldHideCreatorIdentity
                    )
                    .padding(.bottom, 14)

                    DetailTitle(ping: viewModel.ping)
                        .padding(.bottom, 10)

                    if let description = viewModel.ping.description,
                       !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        DetailDescription(text: description)
                            .padding(.bottom, 18)
                    }

                    if let imageUrl = viewModel.ping.imageUrl, let url = URL(string: imageUrl) {
                        RetryableAsyncImage(url: url, maxHeight: 300, cornerRadius: 16)
                            .padding(.bottom, 18)
                    }

                    DetailStatsCard(
                        ping: viewModel.ping,
                        isCreator: viewModel.isCreator,
                        hasUserBoosted: viewModel.hasUserBoosted,
                        canBoost: viewModel.canBoost,
                        onBoost: { Task { await viewModel.boostPing() } }
                    )
                    .padding(.bottom, 18)

                    if viewModel.ping.isHot {
                        FeedHotBadge()
                            .padding(.bottom, 14)
                    }

                    DetailJoinChatButton(onJoinChat: handleJoinChat)
                        .padding(.bottom, 14)

                    if viewModel.isCreator {
                        DetailDeleteButton(
                            isDeleting: viewModel.isDeleting,
                            onDelete: handleDeleteTap
                        )
                        .padding(.bottom, 14)
                    }

                    if !viewModel.isCreator {
                        DetailActionLinks(
                            onReport: { showReportSheet = true },
                            onBlock: { showBlockConfirmation = true }
                        )
                        .padding(.bottom, 14)
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .font(.dmSans(.regular, size: 13, relativeTo: .footnote))
                            .foregroundStyle(Color.pingHot)
                            .padding(.bottom, 14)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color.pingBackground)
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToChat) {
            if let chatId = viewModel.ping.chatId {
                ChatView(chatId: chatId, pingId: viewModel.ping.id ?? "", pingCreatorId: viewModel.ping.creatorId)
            }
        }
        .overlay {
            PingItConfirmationDialog(
                isPresented: showDeleteConfirmation,
                onDismiss: { showDeleteConfirmation = false }
            ) {
                DialogTitleBlock(
                    title: "Delete this ping?",
                    message: "It disappears for everyone in the chat too."
                )
                DialogButtonRow {
                    Button("Keep it") { showDeleteConfirmation = false }
                        .buttonStyle(DialogSecondaryButtonStyle())
                } trailing: {
                    Button("Delete", action: handleConfirmDelete)
                        .buttonStyle(DialogDestructiveButtonStyle())
                }
            }
        }
        .overlay {
            PingItConfirmationDialog(
                isPresented: showBlockConfirmation,
                onDismiss: { showBlockConfirmation = false }
            ) {
                DialogTitleBlock(
                    title: "Block this user?",
                    message: "You won't see their pings or messages."
                )
                DialogButtonRow {
                    Button("Cancel") { showBlockConfirmation = false }
                        .buttonStyle(DialogSecondaryButtonStyle())
                } trailing: {
                    Button("Block") {
                        showBlockConfirmation = false
                        Task {
                            try? await blockService.blockUser(viewModel.ping.creatorId)
                            dismiss()
                        }
                    }
                    .buttonStyle(DialogDestructiveButtonStyle())
                }
            }
        }
        .sheet(isPresented: $showReportSheet) {
            if let pingId = viewModel.ping.id {
                ReportView(
                    targetType: .ping,
                    targetId: pingId,
                    targetOwnerId: viewModel.ping.creatorId,
                    targetContent: [viewModel.ping.text, viewModel.ping.description].compactMap { $0 }.joined(separator: "\n"),
                    reportService: reportService,
                    blockService: blockService,
                    onDidBlock: { dismiss() }
                )
            }
        }
        .overlay(alignment: .top) {
            if viewModel.pingUnavailable {
                MapAlertChip(
                    severity: .error,
                    icon: "mappin.slash",
                    title: "Ping unavailable",
                    message: "This ping is no longer available."
                )
                .padding(.horizontal, 16)
                .padding(.top, 60)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.pingUnavailable)
        .task(id: viewModel.pingUnavailable) {
            guard viewModel.pingUnavailable else { return }
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled {
                navigateToChat = false
                dismiss()
            }
        }
        .task {
            viewModel.configure(
                authService: authService,
                pingService: pingService,
                chatService: chatService,
                userService: userService,
                analyticsService: analyticsService
            )
            await viewModel.loadCreator()
            await viewModel.checkBoostStatus()
            viewModel.startCountdownTimer()
            viewModel.startObservingPing()
        }
        .onDisappear(perform: handleDisappear)
        .onChange(of: viewModel.didDeletePing) { _, didDelete in
            if didDelete { dismiss() }
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
        showDeleteConfirmation = false
        Task { await viewModel.deletePing() }
    }
}

// MARK: - Nav Bar

private struct DetailNavBar: View {
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.pingTextPrimary)
                    .frame(width: 38, height: 38)
                    .background(Color.pingSurfaceElevated)
                    .clipShape(.circle)
                    .overlay(
                        Circle().strokeBorder(Color.pingBorder, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Text("Ping Details")
                .font(.syne(.extraBold, size: 20, relativeTo: .title3))
                .foregroundStyle(Color.pingTextPrimary)

            Spacer()
        }
        .padding(.top, 8)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

// MARK: - Author Timer Row

private struct DetailAuthorTimerRow: View {
    let creator: User?
    let createdAt: Date?
    let expiresAt: Date
    let urgency: PingUrgency
    let countdownText: String
    let hideIdentity: Bool

    var body: some View {
        HStack {
            HStack(spacing: 10) {
                DetailAvatar(creator: hideIdentity ? nil : creator, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text("@\(displayName)")
                        .font(.syne(.bold, size: 16, relativeTo: .headline))
                        .foregroundStyle(Color.pingTextPrimary)

                    if let createdAt {
                        Text(createdAt.relativeDescription)
                            .font(.dmSans(.regular, size: 12, relativeTo: .caption))
                            .foregroundStyle(Color.pingTextSecondary)
                    }
                }
            }

            Spacer()

            DetailUrgencyPill(countdownText: countdownText, urgency: urgency)
        }
        .accessibilityElement(children: .combine)
    }

    private var displayName: String {
        if hideIdentity { return "anonymous" }
        return creator?.username ?? "..."
    }
}

// MARK: - Detail Avatar

private struct DetailAvatar: View {
    let creator: User?
    let size: CGFloat

    var body: some View {
        if let urlString = creator?.profileImageUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                avatarPlaceholder
            }
            .frame(width: size, height: size)
            .clipShape(.circle)
        } else {
            avatarPlaceholder
        }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(avatarColor)
            .frame(width: size, height: size)
            .overlay(
                Text(initial)
                    .font(.syne(.extraBold, size: size * 0.38))
                    .foregroundStyle(.white)
            )
    }

    private var initial: String {
        let name = creator?.username ?? "?"
        return String(name.prefix(1)).uppercased()
    }

    private var avatarColor: Color {
        guard let name = creator?.username else { return .pingTextSecondary }
        var hash = 0
        for char in name.unicodeScalars {
            hash = Int(char.value) &+ (hash &<< 6) &+ (hash &<< 16) &- hash
        }
        let hue = Double(abs(hash) % 360) / 360.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.8)
    }
}

// MARK: - Urgency Pill

private struct DetailUrgencyPill: View {
    let countdownText: String
    let urgency: PingUrgency

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "clock")
                .font(.system(size: 13))
            Text(countdownText)
                .font(.dmSans(.bold, size: 13, relativeTo: .footnote))
        }
        .foregroundStyle(urgency.color)
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color.pingAccent.opacity(0.1))
        .overlay(
            Capsule().strokeBorder(Color.pingAccent.opacity(0.2), lineWidth: 1)
        )
        .clipShape(.capsule)
    }
}

// MARK: - Title

private struct DetailTitle: View {
    let ping: Ping

    var body: some View {
        Text(titleText)
            .font(.syne(.extraBold, size: 26, relativeTo: .title))
            .foregroundStyle(Color.pingTextPrimary)
            .tracking(-0.5)
            .lineSpacing(2)
            .lineLimit(3)
    }

    private var titleText: String {
        if let category = ping.category.flatMap(PingCategory.init(rawValue:)) {
            return "\(category.emoji)  \(ping.text)"
        }
        return ping.text
    }
}

// MARK: - Description

private struct DetailDescription: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.dmSans(.regular, size: 15, relativeTo: .body))
            .foregroundStyle(Color.pingTextSecondary)
            .lineSpacing(5)
    }
}

// MARK: - Stats Card

private struct DetailStatsCard: View {
    let ping: Ping
    let isCreator: Bool
    let hasUserBoosted: Bool
    let canBoost: Bool
    let onBoost: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            if isCreator {
                DetailBoostDisplay(ping: ping)
            } else {
                DetailBoostButton(
                    ping: ping,
                    hasUserBoosted: hasUserBoosted,
                    canBoost: canBoost,
                    onBoost: onBoost
                )
            }

            Rectangle()
                .fill(Color.pingBorder)
                .frame(width: 1)

            DetailMemberCount(count: ping.participantCount)
        }
        .frame(maxWidth: .infinity)
        .background(Color.pingSurface)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.pingBorder, lineWidth: 1)
        )
    }
}

// MARK: - Boost Button

private struct DetailBoostButton: View {
    let ping: Ping
    let hasUserBoosted: Bool
    let canBoost: Bool
    let onBoost: () -> Void

    var body: some View {
        Button(action: onBoost) {
            HStack(spacing: 6) {
                Image(systemName: hasUserBoosted ? "flame.fill" : "flame")
                    .font(.system(size: 16))
                Text("\(ping.boostCount)")
                    .font(.dmSans(.bold, size: 15, relativeTo: .body))
                Text(hasUserBoosted ? "boosted" : "boost")
                    .font(.dmSans(.regular, size: 13, relativeTo: .footnote))
            }
            .foregroundStyle(hasUserBoosted ? Color.pingAccent : .pingTextSecondary)
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(
                hasUserBoosted
                    ? Color.pingAccent.opacity(0.15)
                    : Color.pingSurfaceElevated
            )
            .overlay(alignment: .trailing) {
                if hasUserBoosted {
                    Capsule()
                        .strokeBorder(Color.pingAccent, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!canBoost)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: hasUserBoosted)
        .accessibilityLabel(hasUserBoosted ? "Boosted" : "Boost this ping")
        .accessibilityValue("\(ping.boostCount) boosts")
    }
}

// MARK: - Boost Display (creator, non-tappable)

private struct DetailBoostDisplay: View {
    let ping: Ping

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame")
                .font(.system(size: 16))
            Text("\(ping.boostCount)")
                .font(.dmSans(.bold, size: 15, relativeTo: .body))
            Text("boosts")
                .font(.dmSans(.regular, size: 13, relativeTo: .footnote))
        }
        .foregroundStyle(ping.boostCount > 0 ? Color.pingAccent : .pingTextSecondary)
        .frame(maxWidth: .infinity)
        .padding(14)
        .accessibilityLabel("Boost count")
        .accessibilityValue("\(ping.boostCount)")
    }
}

// MARK: - Member Count

private struct DetailMemberCount: View {
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "person.2")
                .font(.system(size: 14))
            Text("\(count)")
                .font(.dmSans(.bold, size: 15, relativeTo: .body))
            Text("in chat")
                .font(.dmSans(.regular, size: 13, relativeTo: .footnote))
        }
        .foregroundStyle(Color.pingTextSecondary)
        .frame(maxWidth: .infinity)
        .padding(14)
        .accessibilityLabel("Members in chat")
        .accessibilityValue("\(count)")
    }
}

// MARK: - Join Chat Button

private struct DetailJoinChatButton: View {
    let onJoinChat: () -> Void

    var body: some View {
        Button(action: onJoinChat) {
            HStack(spacing: 8) {
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 16))
                Text("JOIN CHAT")
                    .font(.syne(.extraBold, size: 17))
                    .tracking(-0.3)
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.pingAccent)
            .clipShape(.capsule)
            .shadow(color: Color.pingAccent.opacity(0.4), radius: 14, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Join chat")
    }
}

// MARK: - Delete Button

private struct DetailDeleteButton: View {
    let isDeleting: Bool
    let onDelete: () -> Void

    var body: some View {
        Button(action: onDelete) {
            HStack(spacing: 6) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                Text("Delete Ping")
                    .font(.dmSans(.semiBold, size: 14, relativeTo: .body))
            }
            .foregroundStyle(Color.pingHot)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.pingHot.opacity(0.07))
            .clipShape(.capsule)
            .overlay(
                Capsule().strokeBorder(Color.pingHot.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDeleting)
        .opacity(isDeleting ? 0.6 : 1)
        .accessibilityLabel("Delete this ping")
    }
}

// MARK: - Action Links (Report / Block)

private struct DetailActionLinks: View {
    let onReport: () -> Void
    let onBlock: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onReport) {
                DetailActionPillLabel(
                    icon: "exclamationmark.bubble",
                    text: "Report",
                    foreground: Color.pingTextSecondary,
                    border: Color.pingBorder
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Report this ping")

            Button(action: onBlock) {
                DetailActionPillLabel(
                    icon: "hand.raised",
                    text: "Block User",
                    foreground: Color.pingHot,
                    border: Color.pingHot.opacity(0.35)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Block this user")
        }
    }
}

private struct DetailActionPillLabel: View {
    let icon: String
    let text: String
    let foreground: Color
    let border: Color

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
            Text(text)
                .font(.dmSans(.semiBold, size: 13, relativeTo: .footnote))
        }
        .foregroundStyle(foreground)
        .frame(maxWidth: .infinity)
        .frame(height: 42)
        .background(Color.pingSurface, in: .capsule)
        .overlay(
            Capsule().strokeBorder(border, lineWidth: 1)
        )
    }
}
