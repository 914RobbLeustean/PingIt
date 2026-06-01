import SwiftUI

struct CreatePingCategorySection: View {
    @Binding var selectedCategory: PingCategory?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CreatePingSectionLabel(title: "What kind of moment?")

            FlowLayout(spacing: 8) {
                ForEach(PingCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        label: category.label,
                        emoji: category.emoji,
                        isSelected: selectedCategory == category,
                        action: { handleCategoryTap(category) }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func handleCategoryTap(_ category: PingCategory) {
        if selectedCategory == category {
            selectedCategory = nil
        } else {
            selectedCategory = category
        }
    }
}
