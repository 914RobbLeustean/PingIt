import SwiftUI

struct UserProfileView: View {
    @Environment(FollowService.self) private var followService
    @Environment(UserService.self) private var userService
    @Environment(PingService.self) private var pingService
    @Environment(AuthService.self) private var authService
    @Environment(BlockService.self) private var blockService
    @Environment(ReportService.self) private var reportService
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: UserProfileViewModel
    @State private var showReportSheet = false
    @State private var showBlockConfirmation = false

    init(userId: String) {
        self._viewModel = State(initialValue: UserProfileViewModel(userId: userId))
    }

    var body: some View {
        VStack(spacing: 0) {
            UserProfileNavBar(onBack: { dismiss() })

            if viewModel.isLoading {
                Spacer()
                ProgressView()
                    .tint(Color.pingAccent)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        UserProfileHero(
                            displayName: viewModel.displayName,
                            initial: viewModel.avatarInitial,
                            profileImageUrl: viewModel.isPrivate ? nil : viewModel.user?.profileImageUrl,
                            isPrivate: viewModel.isPrivate,
                            memberSince: viewModel.memberSinceFormatted
                        )

                        ProfileStatsCard(
                            pingCount: viewModel.pingCount,
                            boostCount: viewModel.totalBoosts,
                            followerCount: viewModel.followerCount
                        )

                        if !viewModel.isOwnProfile {
                            VStack(spacing: 12) {
                                UserProfileFollowButton(
                                    isFollowing: viewModel.isFollowing,
                                    isEnabled: viewModel.canToggleFollow,
                                    isBusy: viewModel.isTogglingFollow || viewModel.isCheckingFollowStatus,
                                    onToggle: { Task { await viewModel.toggleFollow() } }
                                )

                                if viewModel.isPrivate && !viewModel.isFollowing {
                                    Text("This profile is private.")
                                        .font(.dmSans(.regular, size: 13, relativeTo: .footnote))
                                        .foregroundStyle(Color.pingTextSecondary)
                                }

                                UserProfileActionLinks(
                                    onReport: { showReportSheet = true },
                                    onBlock: { showBlockConfirmation = true }
                                )
                            }
                            .padding(.horizontal, 20)
                        }

                        if let errorMessage = viewModel.errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.triangle")
                                .font(.dmSans(.regular, size: 13, relativeTo: .footnote))
                                .foregroundStyle(Color.pingHot)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 60)
                }
                .scrollIndicators(.hidden)
            }
        }
        .background(Color.pingBackground)
        .navigationBarHidden(true)
        .overlay {
            PingItConfirmationDialog(
                isPresented: showBlockConfirmation,
                onDismiss: { showBlockConfirmation = false }
            ) {
                DialogTitleBlock(
                    title: "Block this user?",
                    message: "You won't see their pings or messages, and any follows are removed."
                )
                DialogButtonRow {
                    Button("Cancel") { showBlockConfirmation = false }
                        .buttonStyle(DialogSecondaryButtonStyle())
                } trailing: {
                    Button("Block") {
                        showBlockConfirmation = false
                        Task {
                            try? await blockService.blockUser(viewModel.userId)
                            dismiss()
                        }
                    }
                    .buttonStyle(DialogDestructiveButtonStyle())
                }
            }
        }
        .sheet(isPresented: $showReportSheet) {
            ReportView(
                targetType: .user,
                targetId: viewModel.userId,
                targetOwnerId: viewModel.userId,
                targetContent: viewModel.user?.username,
                reportService: reportService,
                blockService: blockService,
                onDidBlock: { dismiss() }
            )
        }
        .task {
            viewModel.configure(
                followService: followService,
                userService: userService,
                pingService: pingService,
                authService: authService
            )
            await viewModel.load()
        }
    }
}

// MARK: - Nav Bar

private struct UserProfileNavBar: View {
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

            Text("Profile")
                .font(.syne(.extraBold, size: 20, relativeTo: .title3))
                .foregroundStyle(Color.pingTextPrimary)

            Spacer()
        }
        .padding(.top, 8)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

// MARK: - Hero

private struct UserProfileHero: View {
    let displayName: String
    let initial: String
    let profileImageUrl: String?
    let isPrivate: Bool
    let memberSince: String

    var body: some View {
        VStack(spacing: 12) {
            Group {
                if isPrivate {
                    Circle()
                        .fill(Color.pingSurfaceElevated)
                        .frame(width: 86, height: 86)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(Color.pingTextSecondary)
                        )
                } else {
                    SocialAvatar(username: displayName, profileImageUrl: profileImageUrl, size: 86)
                }
            }
            .overlay(
                Circle().strokeBorder(Color.pingAccent.opacity(0.4), lineWidth: 3)
            )
            .shadow(color: Color.pingAccent.opacity(0.25), radius: 12)

            VStack(spacing: 3) {
                Text("@\(displayName)")
                    .font(.syne(.extraBold, size: 22, relativeTo: .title2))
                    .foregroundStyle(Color.pingTextPrimary)
                    .tracking(-0.4)

                Text("Member since \(memberSince)")
                    .font(.dmSans(.regular, size: 13, relativeTo: .footnote))
                    .foregroundStyle(Color.pingTextSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Follow Button

private struct UserProfileFollowButton: View {
    let isFollowing: Bool
    let isEnabled: Bool
    let isBusy: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 8) {
                if isBusy {
                    ProgressView()
                        .tint(isFollowing ? Color.pingLive : .black)
                } else {
                    Image(systemName: isFollowing ? "checkmark.circle.fill" : "person.badge.plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text(isFollowing ? "FOLLOWING" : "FOLLOW")
                        .font(.syne(.extraBold, size: 15))
                        .tracking(-0.3)
                }
            }
            .foregroundStyle(isFollowing ? Color.pingLive : .black)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                isFollowing ? Color.pingLive.opacity(0.13) : Color.pingAccent,
                in: .capsule
            )
            .overlay(
                Capsule().strokeBorder(
                    isFollowing ? Color.pingLive.opacity(0.45) : .clear,
                    lineWidth: 1
                )
            )
            .shadow(color: isFollowing ? .clear : Color.pingAccent.opacity(0.35), radius: 12, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled || isBusy ? 1 : 0.5)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isFollowing)
        .accessibilityLabel(isFollowing ? "Unfollow this user" : "Follow this user")
    }
}

// MARK: - Action Links

private struct UserProfileActionLinks: View {
    let onReport: () -> Void
    let onBlock: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onReport) {
                actionPill(icon: "exclamationmark.bubble", text: "Report", foreground: Color.pingTextSecondary, border: Color.pingBorder)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Report this user")

            Button(action: onBlock) {
                actionPill(icon: "hand.raised", text: "Block", foreground: Color.pingHot, border: Color.pingHot.opacity(0.35))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Block this user")
        }
    }

    private func actionPill(icon: String, text: String, foreground: Color, border: Color) -> some View {
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
