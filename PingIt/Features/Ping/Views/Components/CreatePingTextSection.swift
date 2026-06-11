import SwiftUI

struct CreatePingTextSection: View {
    @Binding var text: String
    let characterCount: Int
    let isOverLimit: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CreatePingSectionLabel(title: "What's happening right now?")

            VStack(alignment: .trailing, spacing: 6) {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .font(.dmSans(.regular, size: 15, relativeTo: .body))
                        .foregroundStyle(Color.pingTextPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(14)
                        .frame(minHeight: 90)

                    if text.isEmpty {
                        Text("Be specific. Be real.")
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

                Text("\(characterCount)/280")
                    .font(.dmSans(.regular, size: 12, relativeTo: .caption))
                    .foregroundStyle(isOverLimit ? Color.pingHot : .pingTextSecondary)
                    .padding(.trailing, 24)
                    .accessibilityLabel("Character count")
                    .accessibilityValue("\(characterCount) of 280")
            }
        }
        .onChange(of: text) { _, newValue in
            if newValue.count > 280 {
                text = String(newValue.prefix(280))
            }
        }
    }
}
