import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    let sender: User?
    let showSenderInfo: Bool
    let isSenderPrivate: Bool
    let onReport: () -> Void
    let onBlock: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isCurrentUser {
                Spacer(minLength: 48)
            } else {
                avatarView
            }

            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 2) {
                if showSenderInfo && !isCurrentUser {
                    Text(isSenderPrivate ? "Anonymous" : (sender?.username ?? "Unknown"))
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }

                Text(message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isCurrentUser ? Color.accentColor : Color(.systemGray5))
                    .foregroundStyle(isCurrentUser ? .white : .primary)
                    .clipShape(.rect(cornerRadius: 16))
                    .contextMenu {
                        if !isCurrentUser {
                            Button("Report Message", systemImage: "exclamationmark.bubble") {
                                onReport()
                            }
                            Button("Block User", systemImage: "hand.raised", role: .destructive) {
                                onBlock()
                            }
                        }
                    }

                if let createdAt = message.createdAt {
                    Text(createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if isCurrentUser {
                // No avatar on right side for current user — matches iMessage/WhatsApp
            } else {
                Spacer(minLength: 48)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let senderName = isCurrentUser ? "You" : (isSenderPrivate ? "Anonymous" : (sender?.username ?? "Unknown"))
        return "\(senderName): \(message.text)"
    }

    @ViewBuilder
    private var avatarView: some View {
        if showSenderInfo {
            if isSenderPrivate {
                anonymousAvatarView
            } else {
                AsyncImage(url: sender?.profileImageUrl.flatMap { URL(string: $0) }) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        senderInitialView
                    default:
                        senderInitialView
                    }
                }
                .frame(width: 28, height: 28)
                .clipShape(.circle)
            }
        } else {
            // Invisible spacer to keep alignment with messages that have avatars
            Color.clear
                .frame(width: 28, height: 28)
        }
    }

    private var senderInitialView: some View {
        Circle()
            .fill(Color(.systemGray4))
            .frame(width: 28, height: 28)
            .overlay {
                Text(String((sender?.username ?? "?").prefix(1)).uppercased())
                    .font(.caption2)
                    .bold()
                    .foregroundStyle(.secondary)
            }
    }

    private var anonymousAvatarView: some View {
        Circle()
            .fill(Color(.systemGray4))
            .frame(width: 28, height: 28)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
    }
}
