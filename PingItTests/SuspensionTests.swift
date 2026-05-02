import Testing
@testable import PingIt

@Suite("Suspension Logic")
@MainActor
struct SuspensionTests {

    private func makeUser(
        suspensionStatus: String? = nil,
        suspensionExpiresAt: Date? = nil
    ) -> User {
        var user = User(username: "testuser", email: "test@test.com", usernameLowercase: "testuser")
        user.suspensionStatus = suspensionStatus
        user.suspensionExpiresAt = suspensionExpiresAt
        return user
    }

    private func isSuspended(_ user: User) -> Bool {
        guard let status = user.suspensionStatus else { return false }
        guard status == "suspended" || status == "banned" else { return false }
        if status == "banned" { return true }
        if let expiresAt = user.suspensionExpiresAt {
            return expiresAt > Date.now
        }
        return true
    }

    @Test func userWithNoSuspensionFieldsIsNotSuspended() {
        let user = makeUser()
        #expect(!isSuspended(user))
    }

    @Test func userWithSuspendedStatusAndFutureExpiryIsSuspended() {
        let user = makeUser(
            suspensionStatus: "suspended",
            suspensionExpiresAt: Date.now.addingTimeInterval(86400)
        )
        #expect(isSuspended(user))
    }

    @Test func userWithSuspendedStatusAndPastExpiryIsNotSuspended() {
        let user = makeUser(
            suspensionStatus: "suspended",
            suspensionExpiresAt: Date.now.addingTimeInterval(-3600)
        )
        #expect(!isSuspended(user))
    }

    @Test func userWithSuspendedStatusAndNoExpiryIsPermanentlySuspended() {
        let user = makeUser(suspensionStatus: "suspended")
        #expect(isSuspended(user))
    }

    @Test func userWithBannedStatusIsAlwaysSuspended() {
        let user = makeUser(suspensionStatus: "banned")
        #expect(isSuspended(user))
    }

    @Test func userWithBannedStatusIgnoresExpiry() {
        let user = makeUser(
            suspensionStatus: "banned",
            suspensionExpiresAt: Date.now.addingTimeInterval(-86400)
        )
        #expect(isSuspended(user))
    }

    @Test func userWithUnknownStatusIsNotSuspended() {
        let user = makeUser(suspensionStatus: "warned")
        #expect(!isSuspended(user))
    }
}
