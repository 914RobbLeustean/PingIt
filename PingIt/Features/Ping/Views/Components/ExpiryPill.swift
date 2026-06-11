import SwiftUI

struct ExpiryPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.dmSans(isSelected ? .bold : .medium, size: 13, relativeTo: .subheadline))
                .foregroundStyle(isSelected ? Color.pingAccent : .pingTextSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
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
