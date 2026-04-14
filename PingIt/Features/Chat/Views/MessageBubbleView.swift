import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    let onReport: () -> Void
    let onBlock: () -> Void

    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }

            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
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
                    let style = Date.FormatStyle(timeZone: TimeZone(identifier: "Europe/Bucharest") ?? .current)
                        .hour()
                        .minute()
                    Text(createdAt.formatted(style))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if isCurrentUser == false { Spacer() }
        }
    }
}
