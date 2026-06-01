import SwiftUI

struct FeedSortChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.dmSans(.medium, size: 12, relativeTo: .caption))
                .foregroundStyle(isSelected ? Color.pingAccent : .pingTextSecondary)
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(isSelected ? Color.pingAccent.opacity(0.13) : .pingSurface)
                .clipShape(.capsule)
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.pingAccent : .pingBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
