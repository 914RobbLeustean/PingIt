import Testing
import Foundation
@testable import PingIt

struct DeepLinkTests {

    // MARK: - Custom scheme

    @Test func parsesCustomSchemePingURL() {
        let url = URL(string: "pingit://ping/abc123")!
        #expect(DeepLink(url: url) == .ping(id: "abc123"))
    }

    @Test func rejectsCustomSchemeWithWrongHost() {
        let url = URL(string: "pingit://chat/abc123")!
        #expect(DeepLink(url: url) == nil)
    }

    @Test func rejectsCustomSchemeWithoutPingId() {
        let url = URL(string: "pingit://ping")!
        #expect(DeepLink(url: url) == nil)
    }

    // MARK: - Web links

    @Test func parsesWebPingURL() {
        let url = URL(string: "https://pingit-dev.web.app/ping/xyz789")!
        #expect(DeepLink(url: url) == .ping(id: "xyz789"))
    }

    @Test func rejectsWebURLWithWrongHost() {
        let url = URL(string: "https://evil.example.com/ping/xyz789")!
        #expect(DeepLink(url: url) == nil)
    }

    @Test func rejectsWebURLWithWrongPath() {
        let url = URL(string: "https://pingit-dev.web.app/user/xyz789")!
        #expect(DeepLink(url: url) == nil)
    }

    @Test func rejectsWebURLWithExtraPathComponents() {
        let url = URL(string: "https://pingit-dev.web.app/ping/xyz789/extra")!
        #expect(DeepLink(url: url) == nil)
    }

    @Test func rejectsWebRootURL() {
        let url = URL(string: "https://pingit-dev.web.app/")!
        #expect(DeepLink(url: url) == nil)
    }

    @Test func rejectsHTTPWebURL() {
        let url = URL(string: "http://pingit-dev.web.app/ping/xyz789")!
        #expect(DeepLink(url: url) == nil)
    }

    // MARK: - Share URL

    @Test func buildsShareURL() {
        let url = DeepLink.shareURL(forPingId: "abc123")
        #expect(url?.absoluteString == "https://pingit-dev.web.app/ping/abc123")
    }

    @Test func shareURLRoundTripsThroughParser() {
        let url = DeepLink.shareURL(forPingId: "roundtrip1")!
        #expect(DeepLink(url: url) == .ping(id: "roundtrip1"))
    }
}
