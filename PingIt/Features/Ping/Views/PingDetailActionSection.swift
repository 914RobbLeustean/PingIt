import SwiftUI

struct PingDetailActionSection: View {
    let chatId: String?
    let isCreator: Bool
    let isDeleting: Bool
    var onJoinChat: () -> Void
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
        onJoinChat()
    }

    private func handleDelete() {
        onDelete()
    }
}
