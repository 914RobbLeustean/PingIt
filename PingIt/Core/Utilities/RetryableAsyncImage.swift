import SwiftUI

/// Content image (ping photos, recap photos) with automatic retry on
/// failure and ImageCache backing — once loaded, an image renders
/// instantly on every later appearance.
struct RetryableAsyncImage: View {
    let url: URL
    let maxHeight: CGFloat
    let cornerRadius: CGFloat

    @State private var loadedImage: UIImage?
    @State private var attempt = 0
    @State private var hasFailed = false

    private static let maxAttempts = 3

    var body: some View {
        if let image = displayImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxHeight: maxHeight)
                .clipShape(.rect(cornerRadius: cornerRadius))
        } else if hasFailed {
            Color(.systemGray5)
                .frame(height: maxHeight)
                .clipShape(.rect(cornerRadius: cornerRadius))
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
        } else {
            Color(.systemGray5)
                .frame(height: maxHeight)
                .clipShape(.rect(cornerRadius: cornerRadius))
                .overlay { ProgressView() }
                .task(id: attempt) { await load() }
        }
    }

    private var displayImage: UIImage? {
        if let loadedImage { return loadedImage }
        return ImageCache.shared.image(for: url)
    }

    private func load() async {
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad

        if let (data, _) = try? await URLSession.shared.data(for: request),
           let image = UIImage(data: data) {
            ImageCache.shared.store(image, for: url)
            loadedImage = image
            return
        }

        guard attempt < Self.maxAttempts - 1 else {
            hasFailed = true
            return
        }
        try? await Task.sleep(for: .seconds(2))
        if !Task.isCancelled {
            attempt += 1
        }
    }
}
