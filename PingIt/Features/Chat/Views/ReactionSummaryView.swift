import SwiftUI

struct ReactionSummaryView: View {
    let reactions: [String: [String]]
    let currentUserId: String?
    let onToggle: (String) -> Void

    private var sortedReactions: [(emoji: String, userIds: [String])] {
        reactions
            .filter { !$0.value.isEmpty }
            .sorted { $0.key < $1.key }
            .map { (emoji: $0.key, userIds: $0.value) }
    }

    var body: some View {
        if !sortedReactions.isEmpty {
            HStack(spacing: 4) {
                ForEach(sortedReactions, id: \.emoji) { reaction in
                    Button {
                        onToggle(reaction.emoji)
                    } label: {
                        HStack(spacing: 2) {
                            Text(reaction.emoji)
                                .font(.caption)
                            Text(reaction.userIds.count, format: .number)
                                .font(.caption2)
                                .foregroundStyle(currentUserReacted(reaction.userIds) ? .white : .secondary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(currentUserReacted(reaction.userIds) ? Color.accentColor.opacity(0.3) : Color(.systemGray5))
                        .clipShape(.capsule)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(reaction.emoji) \(reaction.userIds.count) reaction\(reaction.userIds.count == 1 ? "" : "s")")
                    .accessibilityHint(currentUserReacted(reaction.userIds) ? "Double tap to remove your reaction" : "Double tap to react")
                }
            }
        }
    }

    private func currentUserReacted(_ userIds: [String]) -> Bool {
        guard let currentUserId else { return false }
        return userIds.contains(currentUserId)
    }
}
