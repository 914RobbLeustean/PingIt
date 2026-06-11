import SwiftUI

/// 20×20pt rounded square checkbox styled per spec.
/// - Empty: surface-elevated fill, 1.5pt amber-20% border.
/// - Checked: solid amber fill with a bold white checkmark.
struct AuthCheckbox: View {
    @Binding var isChecked: Bool
    var action: (() -> Void)?

    var body: some View {
        Button {
            isChecked.toggle()
            action?()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isChecked ? Color.pingAccent : Color.pingSurfaceElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(
                                isChecked ? Color.pingAccent : Color.pingAccent.opacity(0.2),
                                lineWidth: 1.5
                            )
                    )
                    .frame(width: 20, height: 20)

                if isChecked {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.white)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isChecked)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isChecked ? [.isSelected] : [])
    }
}
