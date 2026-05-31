import SwiftUI

struct RetryableAsyncImage: View {
    let url: URL
    let maxHeight: CGFloat
    let cornerRadius: CGFloat

    @State private var retryId = 0
    @State private var hasFailed = false

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxHeight: maxHeight)
                    .clipShape(.rect(cornerRadius: cornerRadius))
            case .failure:
                Color(.systemGray5)
                    .frame(height: maxHeight)
                    .clipShape(.rect(cornerRadius: cornerRadius))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
                    .onAppear { scheduleRetry() }
            default:
                Color(.systemGray5)
                    .frame(height: maxHeight)
                    .clipShape(.rect(cornerRadius: cornerRadius))
                    .overlay { ProgressView() }
            }
        }
        .id(retryId)
    }

    private func scheduleRetry() {
        guard retryId < 3 else { return }
        Task {
            try? await Task.sleep(for: .seconds(2))
            retryId += 1
        }
    }
}
