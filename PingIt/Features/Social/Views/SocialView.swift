import SwiftUI

struct SocialView: View {
    @Environment(FollowService.self) private var followService
    @Environment(AuthService.self) private var authService
    @Environment(BlockService.self) private var blockService
    @State private var viewModel = SocialViewModel()
    @State private var selectedUserId: String?

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            VStack(spacing: 0) {
                SocialHeader()

                SocialSearchField(text: $viewModel.searchText)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 16)

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        if let errorMessage = viewModel.errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.triangle")
                                .font(.dmSans(.regular, size: 13, relativeTo: .footnote))
                                .foregroundStyle(Color.pingHot)
                                .padding(.horizontal, 16)
                        }

                        if viewModel.isShowingSearchResults {
                            searchResults
                        } else {
                            followingSection
                        }
                    }
                    .padding(.bottom, 90)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .background(Color.pingBackground)
            .navigationBarHidden(true)
            .navigationDestination(item: $selectedUserId) { userId in
                UserProfileView(userId: userId)
            }
            .task {
                viewModel.configure(followService: followService, authService: authService)
                viewModel.applyBlockFilter(blockedIds: blockService.blockedUserIds)
                await viewModel.loadFollowing()
            }
            .onChange(of: blockService.blockedUserIds) { _, newValue in
                viewModel.applyBlockFilter(blockedIds: newValue)
            }
        }
    }

    @ViewBuilder
    private var searchResults: some View {
        if viewModel.isSearching {
            HStack {
                Spacer()
                ProgressView()
                    .tint(Color.pingAccent)
                    .padding(.top, 40)
                Spacer()
            }
        } else if viewModel.results.isEmpty {
            SocialEmptyState(
                emoji: "🔍",
                title: "No one found.",
                message: "Try the exact start of their username. Private profiles don't show up here."
            )
        } else {
            SocialUserCard {
                ForEach(Array(viewModel.results.enumerated()), id: \.element.id) { index, result in
                    if index > 0 { SettingsRowDivider() }
                    SocialUserRow(
                        username: result.username,
                        profileImageUrl: result.profileImageUrl,
                        subtitle: followerLabel(result.followerCount),
                        isAnonymous: false,
                        isFollowing: viewModel.isFollowing(result.userId),
                        isBusy: viewModel.togglingUserIds.contains(result.userId),
                        onTap: { selectedUserId = result.userId },
                        onToggleFollow: { Task { await viewModel.toggleFollow(userId: result.userId) } }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var followingSection: some View {
        if viewModel.isLoadingFollowing && viewModel.following.isEmpty {
            HStack {
                Spacer()
                ProgressView()
                    .tint(Color.pingAccent)
                    .padding(.top, 40)
                Spacer()
            }
        } else if viewModel.following.isEmpty {
            SocialEmptyState(
                emoji: "👋",
                title: "You're not following anyone yet.",
                message: "Search a username above to find people and follow what they're up to."
            )
        } else {
            Text("FOLLOWING")
                .font(.dmSans(.semiBold, size: 11, relativeTo: .caption2))
                .tracking(1.2)
                .foregroundStyle(Color.pingTextSecondary)
                .padding(.horizontal, 20)

            SocialUserCard {
                ForEach(Array(viewModel.following.enumerated()), id: \.element.id) { index, user in
                    if index > 0 { SettingsRowDivider() }
                    SocialUserRow(
                        username: user.isPrivateProfile ? "anonymous" : user.username,
                        profileImageUrl: user.isPrivateProfile ? nil : user.profileImageUrl,
                        subtitle: user.isPrivateProfile
                            ? "Gone private"
                            : followerLabel(user.followerCount ?? 0),
                        isAnonymous: user.isPrivateProfile,
                        isFollowing: true,
                        isBusy: viewModel.togglingUserIds.contains(user.id ?? ""),
                        onTap: { selectedUserId = user.id },
                        onToggleFollow: {
                            if let userId = user.id {
                                Task { await viewModel.toggleFollow(userId: userId) }
                            }
                        }
                    )
                }
            }
        }
    }

    private func followerLabel(_ count: Int) -> String {
        count == 1 ? "1 follower" : "\(count) followers"
    }
}

// MARK: - Header

private struct SocialHeader: View {
    var body: some View {
        HStack {
            Text("Social")
                .font(.syne(.extraBold, size: 28, relativeTo: .largeTitle))
                .foregroundStyle(Color.pingTextPrimary)
                .tracking(-0.5)
                .accessibilityAddTraits(.isHeader)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }
}

// MARK: - Search Field

private struct SocialSearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.pingTextSecondary)

            TextField("", text: $text, prompt: Text("Search username...")
                .font(.dmSans(.regular, size: 14))
                .foregroundStyle(Color.pingTextSecondary.opacity(0.7)))
                .font(.dmSans(.regular, size: 14, relativeTo: .body))
                .foregroundStyle(Color.pingTextPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.pingTextSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(Color.pingSurface, in: .capsule)
        .overlay(
            Capsule().strokeBorder(Color.pingBorder, lineWidth: 1)
        )
        .accessibilityLabel("Search users by username")
    }
}

// MARK: - Card Container

private struct SocialUserCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color.pingSurface)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.pingBorder, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - User Row

private struct SocialUserRow: View {
    let username: String
    let profileImageUrl: String?
    let subtitle: String
    let isAnonymous: Bool
    let isFollowing: Bool
    let isBusy: Bool
    let onTap: () -> Void
    let onToggleFollow: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    SocialAvatar(
                        username: username,
                        profileImageUrl: profileImageUrl,
                        size: 40,
                        isAnonymous: isAnonymous
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("@\(username)")
                            .font(.dmSans(.semiBold, size: 15, relativeTo: .body))
                            .foregroundStyle(Color.pingTextPrimary)
                        Text(subtitle)
                            .font(.dmSans(.regular, size: 12, relativeTo: .caption))
                            .foregroundStyle(Color.pingTextSecondary)
                    }

                    Spacer()
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("View profile of \(username)")

            SocialFollowPill(isFollowing: isFollowing, isBusy: isBusy, action: onToggleFollow)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}

// MARK: - Follow Pill

struct SocialFollowPill: View {
    let isFollowing: Bool
    let isBusy: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isBusy {
                    ProgressView()
                        .tint(isFollowing ? Color.pingLive : .black)
                        .scaleEffect(0.7)
                } else {
                    Text(isFollowing ? "Following" : "Follow")
                        .font(.dmSans(.semiBold, size: 12, relativeTo: .caption))
                }
            }
            .foregroundStyle(isFollowing ? Color.pingLive : .black)
            .frame(width: 82, height: 30)
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
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isFollowing)
        .accessibilityLabel(isFollowing ? "Unfollow" : "Follow")
    }
}

// MARK: - Avatar

struct SocialAvatar: View {
    let username: String
    let profileImageUrl: String?
    let size: CGFloat
    var isAnonymous: Bool = false

    var body: some View {
        if isAnonymous {
            Circle()
                .fill(Color.pingSurfaceElevated)
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.4))
                        .foregroundStyle(Color.pingTextSecondary)
                )
        } else if let urlString = profileImageUrl, let url = URL(string: urlString) {
            CachedAsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                placeholder
            }
            .frame(width: size, height: size)
            .clipShape(.circle)
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Circle()
            .fill(avatarColor)
            .frame(width: size, height: size)
            .overlay(
                Text(initial)
                    .font(.syne(.extraBold, size: size * 0.4))
                    .foregroundStyle(.white)
            )
    }

    private var initial: String {
        guard let first = username.first else { return "?" }
        return String(first).uppercased()
    }

    private var avatarColor: Color {
        guard !username.isEmpty else { return .pingTextSecondary }
        var hash = 0
        for char in username.unicodeScalars {
            hash = Int(char.value) &+ (hash &<< 6) &+ (hash &<< 16) &- hash
        }
        let hue = Double(abs(hash) % 360) / 360.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.8)
    }
}

// MARK: - Empty State

private struct SocialEmptyState: View {
    let emoji: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Text(emoji)
                .font(.system(size: 40))
            Text(title)
                .font(.syne(.bold, size: 18, relativeTo: .headline))
                .foregroundStyle(Color.pingTextPrimary)
            Text(message)
                .font(.dmSans(.regular, size: 14, relativeTo: .body))
                .foregroundStyle(Color.pingTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .padding(.top, 60)
        .accessibilityElement(children: .combine)
    }
}
