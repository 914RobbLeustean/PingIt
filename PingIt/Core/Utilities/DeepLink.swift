import Foundation

/// Parses incoming deep link URLs and builds shareable links.
///
/// Two URL forms resolve to the same destination:
/// - Custom scheme: `pingit://ping/{pingId}` — works without Apple Developer
///   Program enrollment; fired by the web fallback page's "Open in PingIt".
/// - Web link: `https://pingit-dev.web.app/ping/{pingId}` — the shareable
///   form; opens the hosting fallback page for users without the app.
///   Becomes a universal link once associated domains are configured.
enum DeepLink: Equatable {
    case ping(id: String)

    static let customScheme = "pingit"
    static let webHost = "pingit-dev.web.app"

    init?(url: URL) {
        if url.scheme == Self.customScheme {
            // pingit://ping/{pingId} — host is "ping", path is "/{pingId}"
            guard url.host == "ping" else { return nil }
            let id = url.lastPathComponent
            guard !id.isEmpty, id != "/" else { return nil }
            self = .ping(id: id)
            return
        }

        if url.scheme == "https", url.host == Self.webHost {
            // https://pingit-dev.web.app/ping/{pingId}
            let components = url.pathComponents.filter { $0 != "/" }
            guard components.count == 2, components[0] == "ping", !components[1].isEmpty else {
                return nil
            }
            self = .ping(id: components[1])
            return
        }

        return nil
    }

    static func shareURL(forPingId pingId: String) -> URL? {
        URL(string: "https://\(webHost)/ping/\(pingId)")
    }
}
