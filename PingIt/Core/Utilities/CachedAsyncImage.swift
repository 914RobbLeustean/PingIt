import SwiftUI

/// Drop-in AsyncImage replacement backed by ImageCache. The cache is checked
/// synchronously in `body`, so a view recreated by a list refresh renders the
/// cached image on its first frame — no placeholder flash. Misses load via
/// URLSession (which also persists to URLCache on disk) and populate the cache.
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    @State private var loadedImage: UIImage?

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        if let image = displayImage {
            content(Image(uiImage: image))
        } else {
            placeholder()
                .task(id: url) { await load() }
        }
    }

    private var displayImage: UIImage? {
        if let loadedImage { return loadedImage }
        guard let url else { return nil }
        return ImageCache.shared.image(for: url)
    }

    private func load() async {
        guard let url else { return }
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let image = UIImage(data: data) else { return }

        ImageCache.shared.store(image, for: url)
        loadedImage = image
    }
}
