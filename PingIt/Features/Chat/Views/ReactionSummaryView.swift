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
                        ReactionChip(
                            emoji: reaction.emoji,
                            count: reaction.userIds.count,
                            isSelected: currentUserReacted(reaction.userIds)
                        )
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

private struct ReactionChip: View {
    let emoji: String
    let count: Int
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 3) {
            Text(emoji)
                .font(.system(size: 12))
            Text(count, format: .number)
                .font(.dmSans(.semiBold, size: 11, relativeTo: .caption2))
                .foregroundStyle(isSelected ? Color.pingAccent : Color.pingTextSecondary)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            isSelected ? Color.pingAccent.opacity(0.18) : Color.pingSurface,
            in: .capsule
        )
        .overlay(
            Capsule()
                .strokeBorder(
                    isSelected ? Color.pingAccent.opacity(0.45) : Color.pingBorder,
                    lineWidth: 1
                )
        )
    }
}
