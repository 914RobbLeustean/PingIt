import Testing
import UIKit
@testable import PingIt

struct ImageCacheTests {

    private func makeImage(size: CGSize = CGSize(width: 10, height: 10)) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { context in
            UIColor.orange.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    @Test func storedImageIsRetrievableByURL() {
        let url = URL(string: "https://example.com/\(UUID().uuidString).jpg")!
        let image = makeImage()

        ImageCache.shared.store(image, for: url)

        #expect(ImageCache.shared.image(for: url) === image)
    }

    @Test func missReturnsNil() {
        let url = URL(string: "https://example.com/never-stored-\(UUID().uuidString).jpg")!
        #expect(ImageCache.shared.image(for: url) == nil)
    }

    @Test func differentURLsAreIndependent() {
        let first = URL(string: "https://example.com/a-\(UUID().uuidString).jpg")!
        let second = URL(string: "https://example.com/b-\(UUID().uuidString).jpg")!
        let firstImage = makeImage()
        let secondImage = makeImage(size: CGSize(width: 20, height: 20))

        ImageCache.shared.store(firstImage, for: first)
        ImageCache.shared.store(secondImage, for: second)

        #expect(ImageCache.shared.image(for: first) === firstImage)
        #expect(ImageCache.shared.image(for: second) === secondImage)
    }

    @Test func storingTwiceReplacesImage() {
        let url = URL(string: "https://example.com/replace-\(UUID().uuidString).jpg")!
        let original = makeImage()
        let replacement = makeImage(size: CGSize(width: 30, height: 30))

        ImageCache.shared.store(original, for: url)
        ImageCache.shared.store(replacement, for: url)

        #expect(ImageCache.shared.image(for: url) === replacement)
    }
}
