import SwiftUI

struct CreatePingExpirySection: View {
    @Binding var selectedIndex: Int
    @Binding var isCustomDuration: Bool
    @Binding var customExpiryDate: Date
    let customExpiryRange: ClosedRange<Date>

    private let presetLabels = ["6h", "24h", "48h", "Custom"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CreatePingSectionLabel(title: "Expires in")

            HStack(spacing: 8) {
                ForEach(presetLabels.indices, id: \.self) { index in
                    ExpiryPill(
                        label: presetLabels[index],
                        isSelected: selectedIndex == index,
                        action: { handlePillTap(index) }
                    )
                }
            }
            .padding(.horizontal, 20)

            if isCustomDuration {
                DatePicker(
                    "Expires at",
                    selection: $customExpiryDate,
                    in: customExpiryRange,
                    displayedComponents: [.hourAndMinute, .date]
                )
                .datePickerStyle(.graphical)
                .tint(Color.pingAccent)
                .labelsHidden()
                .padding(.horizontal, 20)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isCustomDuration)
    }

    private func handlePillTap(_ index: Int) {
        selectedIndex = index
        isCustomDuration = index == 3
    }
}
