import UIKit

/// In-memory image cache keyed by URL. Once an image has been on screen it
/// renders instantly everywhere else — list refreshes, sheet re-presentations,
/// tab switches — with no placeholder flash. NSCache evicts automatically
/// under memory pressure; URLCache (disk) still covers app relaunches.
final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.totalCostLimit = 50 * 1024 * 1024
    }

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url.absoluteString as NSString)
    }

    func store(_ image: UIImage, for url: URL) {
        let cost = Int(image.size.width * image.size.height * image.scale * image.scale * 4)
        cache.setObject(image, forKey: url.absoluteString as NSString, cost: cost)
    }
}
