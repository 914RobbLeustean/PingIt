import SwiftUI

struct BlockedUsersView: View {
    @Environment(BlockService.self) private var blockService
    @Environment(UserService.self) private var userService
    @State private var viewModel = BlockedUsersViewModel()
    @State private var showUnblockConfirmation = false
    @State private var userToUnblock: String?

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.blockedUsers.isEmpty {
                ContentUnavailableView(
                    "No Blocked Users",
                    systemImage: "person.crop.circle.badge.xmark",
                    description: Text("You haven't blocked anyone.")
                )
            } else if let errorMessage = viewModel.errorMessage {
                ContentUnavailableView(
                    "Something went wrong",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
            } else {
                List {
                    ForEach(viewModel.blockedUsers, id: \.block.blockedUserId) { entry in
                        HStack {
                            if let url = entry.user?.profileImageUrl, let imageUrl = URL(string: url) {
                                AsyncImage(url: imageUrl) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(.circle)
                                .accessibilityLabel("Profile picture")
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.secondary)
                                    .accessibilityLabel("Profile picture")
                            }

                            Text(entry.user?.username ?? "Unknown User")
                                .font(.body)

                            Spacer()

                            Button("Unblock", role: .destructive) {
                                userToUnblock = entry.block.blockedUserId
                                showUnblockConfirmation = true
                            }
                            .font(.subheadline)
                        }
                    }
                }
            }
        }
        .navigationTitle("Blocked Users")
        .alert("Unblock user?", isPresented: $showUnblockConfirmation) {
            Button("Unblock", role: .destructive) {
                if let userId = userToUnblock {
                    Task { await viewModel.unblockUser(userId: userId) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll see their pings and messages again.")
        }
        .task {
            viewModel.configure(blockService: blockService, userService: userService)
            await viewModel.loadBlockedUsers()
        }
    }
}
