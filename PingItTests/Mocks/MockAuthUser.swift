@testable import PingIt

struct MockAuthUser: AuthUserRepresentable {
    var uid: String
    var isEmailVerified: Bool = false
}
