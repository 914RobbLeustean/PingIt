import SwiftUI

struct LegalDocumentView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let document: LegalDocument

    var body: some View {
        ZStack {
            Color.pingBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                AuthScreenHeader(title: title) { dismiss() }

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(document.blocks.indices, id: \.self) { index in
                            block(for: document.blocks[index])
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func block(for block: LegalDocument.Block) -> some View {
        switch block {
        case .heading(let text):
            Text(text)
                .font(.syne(.extraBold, size: 28, relativeTo: .largeTitle))
                .foregroundStyle(Color.pingTextPrimary)
                .padding(.top, 4)

        case .updated(let text):
            Text(text)
                .font(.dmSans(.regular, size: 13, relativeTo: .footnote))
                .foregroundStyle(Color.pingTextSecondary)
                .padding(.bottom, 4)

        case .sectionHeading(let text):
            Text(text)
                .font(.syne(.bold, size: 17, relativeTo: .headline))
                .foregroundStyle(Color.pingAccent)
                .padding(.top, 8)

        case .paragraph(let text):
            Text(text)
                .font(.dmSans(.regular, size: 15, relativeTo: .body))
                .foregroundStyle(Color.pingTextPrimary.opacity(0.92))
                .lineSpacing(5)

        case .bullets(let items):
            VStack(alignment: .leading, spacing: 10) {
                ForEach(items.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Color.pingAccent)
                            .frame(width: 5, height: 5)
                            .padding(.top, 8)
                        Text(items[index])
                            .font(.dmSans(.regular, size: 15, relativeTo: .body))
                            .foregroundStyle(Color.pingTextPrimary.opacity(0.92))
                            .lineSpacing(5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }
}
