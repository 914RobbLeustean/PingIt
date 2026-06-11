import SwiftUI

struct CategoryChip: View {
    let label: String
    let emoji: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 14))
                Text(label)
                    .font(.dmSans(isSelected ? .semiBold : .regular, size: 13, relativeTo: .subheadline))
                    .foregroundStyle(isSelected ? Color.pingAccent : .pingTextSecondary)
            }
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(isSelected ? Color.pingAccent.opacity(0.15) : .pingSurfaceElevated)
            .clipShape(.capsule)
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.pingAccent : .pingBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
