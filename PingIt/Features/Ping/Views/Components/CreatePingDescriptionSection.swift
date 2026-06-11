import SwiftUI

struct CreatePingDescriptionSection: View {
    @Binding var text: String
    let characterCount: Int
    let isOverLimit: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CreatePingSectionLabel(title: "Add more details (optional)")

            VStack(alignment: .trailing, spacing: 6) {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .font(.dmSans(.regular, size: 15, relativeTo: .body))
                        .foregroundStyle(Color.pingTextPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(14)
                        .frame(minHeight: 72)

                    if text.isEmpty {
                        Text("Give people a reason to join...")
                            .font(.dmSans(.regular, size: 15, relativeTo: .body))
                            .foregroundStyle(Color.pingTextSecondary)
                            .padding(18)
                            .allowsHitTesting(false)
                    }
                }
                .background(Color.pingSurfaceElevated)
                .clipShape(.rect(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.pingBorder, lineWidth: 1)
                )
                .padding(.horizontal, 20)

                Text("\(characterCount)/500")
                    .font(.dmSans(.regular, size: 12, relativeTo: .caption))
                    .foregroundStyle(isOverLimit ? Color.pingHot : .pingTextSecondary)
                    .padding(.trailing, 24)
                    .accessibilityLabel("Description character count")
                    .accessibilityValue("\(characterCount) of 500")
            }
        }
        .onChange(of: text) { _, newValue in
            if newValue.count > 500 {
                text = String(newValue.prefix(500))
            }
        }
    }
}
