import SwiftUI

struct BlockedUsersView: View {
    @Environment(BlockService.self) private var blockService
    @Environment(UserService.self) private var userService
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = BlockedUsersViewModel()
    @State private var showUnblockDialog = false
    @State private var userToUnblock: BlockedEntry?
    @State private var isUnblocking = false

    var body: some View {
        ZStack {
            Color.pingBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                AuthScreenHeader(title: "Blocked Users") { dismiss() }
                content
            }

            unblockDialog
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            viewModel.configure(blockService: blockService, userService: userService)
            await viewModel.loadBlockedUsers()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            loadingState
        } else if let errorMessage = viewModel.errorMessage, viewModel.blockedUsers.isEmpty {
            BlockedUsersEmptyState(
                title: "Couldn't load blocked users",
                message: errorMessage,
                systemImage: "exclamationmark.triangle"
            )
            .padding(.top, 64)
            Spacer()
        } else if viewModel.blockedUsers.isEmpty {
            BlockedUsersEmptyState(
                title: "No one's blocked",
                message: "Anyone you block will appear here. You can unblock them at any time.",
                systemImage: "person.crop.circle.badge.checkmark"
            )
            .padding(.top, 64)
            Spacer()
        } else {
            list
        }
    }

    private var loadingState: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(Color.pingTextSecondary)
            Spacer()
        }
    }

    private var list: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("PEOPLE YOU'VE BLOCKED")
                    .font(.dmSans(.semiBold, size: 11, relativeTo: .caption2))
                    .tracking(0.8)
                    .foregroundStyle(Color.pingTextSecondary)
                    .padding(.leading, 24)

                VStack(spacing: 0) {
                    ForEach(viewModel.blockedUsers.enumerated(), id: \.element.block.blockedUserId) { index, entry in
                        BlockedUserRow(
                            username: entry.user?.username ?? "Unknown",
                            avatarURL: entry.user?.profileImageUrl.flatMap(URL.init(string:)),
                            onUnblock: { promptUnblock(entry) }
                        )
                        if index < viewModel.blockedUsers.count - 1 {
                            SettingsRowDivider()
                        }
                    }
                }
                .background(Color.pingSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.pingBorder, lineWidth: 1)
                )
                .clipShape(.rect(cornerRadius: 20))
                .padding(.horizontal, 20)
            }
            .padding(.top, 4)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private var unblockDialog: some View {
        PingItConfirmationDialog(isPresented: showUnblockDialog, onDismiss: dismissUnblockDialog) {
            DialogTitleBlock(
                title: "Unblock \(userToUnblock?.user?.username ?? "user")?",
                message: "You'll see their pings and messages again. You can block them later if you change your mind."
            )
            DialogButtonRow {
                Button("Cancel", action: dismissUnblockDialog)
                    .buttonStyle(DialogSecondaryButtonStyle())
            } trailing: {
                Button(action: confirmUnblock) {
                    if isUnblocking {
                        ProgressView().tint(.white)
                    } else {
                        Text("Unblock")
                    }
                }
                .buttonStyle(UnblockConfirmButtonStyle(isLoading: isUnblocking))
                .disabled(isUnblocking)
            }
        }
    }

    // MARK: - Actions

    private func promptUnblock(_ entry: BlockedEntry) {
        userToUnblock = entry
        showUnblockDialog = true
    }

    private func dismissUnblockDialog() {
        guard !isUnblocking else { return }
        showUnblockDialog = false
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            userToUnblock = nil
        }
    }

    private func confirmUnblock() {
        guard let entry = userToUnblock else { return }
        isUnblocking = true
        Task {
            await viewModel.unblockUser(userId: entry.block.blockedUserId)
            isUnblocking = false
            showUnblockDialog = false
            try? await Task.sleep(for: .milliseconds(300))
            userToUnblock = nil
        }
    }
}

private struct UnblockConfirmButtonStyle: ButtonStyle {
    var isLoading: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.syne(.bold, size: 15))
            .tracking(-0.2)
            .foregroundStyle(Color.black)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.pingAccent)
            )
            .shadow(color: Color.pingAccent.opacity(0.35), radius: 12, y: 0)
            .opacity(isLoading ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

typealias BlockedEntry = (block: Block, user: User?)
