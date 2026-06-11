import Testing
import Foundation
import FirebaseFirestore
@testable import PingIt

struct PingRecapTests {

    private func makeRecap(
        attendeeIds: [String] = ["user1", "user2"],
        photoCount: Int = 0,
        recapWindowClosesAt: Date = Date.now.addingTimeInterval(3600)
    ) -> PingRecap {
        PingRecap(
            id: "recap1",
            pingId: "recap1",
            title: "Pickup basketball",
            category: "sports",
            location: GeoPoint(latitude: 46.77, longitude: 23.62),
            attendeeIds: attendeeIds,
            photoCount: photoCount,
            expiresAt: Date.now.addingTimeInterval(-3600),
            recapWindowClosesAt: recapWindowClosesAt,
            ghostExpiresAt: Date.now.addingTimeInterval(23 * 3600)
        )
    }

    // MARK: - Submission eligibility

    @Test func attendeeCanSubmitInsideWindow() {
        let recap = makeRecap()
        #expect(recap.canSubmitPhotos(userId: "user1", now: .now))
    }

    @Test func nonAttendeeCannotSubmit() {
        let recap = makeRecap()
        #expect(recap.canSubmitPhotos(userId: "stranger", now: .now) == false)
    }

    @Test func attendeeCannotSubmitAfterWindowCloses() {
        let recap = makeRecap(recapWindowClosesAt: Date.now.addingTimeInterval(-60))
        #expect(recap.canSubmitPhotos(userId: "user1", now: .now) == false)
    }

    @Test func submissionAllowedRightBeforeWindowCloses() {
        let closesAt = Date.now.addingTimeInterval(5)
        let recap = makeRecap(recapWindowClosesAt: closesAt)
        #expect(recap.canSubmitPhotos(userId: "user1", now: .now))
    }

    @Test func emptyAttendeeListRejectsEveryone() {
        let recap = makeRecap(attendeeIds: [])
        #expect(recap.canSubmitPhotos(userId: "user1", now: .now) == false)
    }

    // MARK: - Map visibility

    @Test func emptyRecapHiddenFromNonAttendees() {
        let recap = makeRecap(photoCount: 0)
        #expect(recap.isVisibleOnMap(to: "stranger") == false)
    }

    @Test func emptyRecapVisibleToAttendees() {
        let recap = makeRecap(photoCount: 0)
        #expect(recap.isVisibleOnMap(to: "user1"))
    }

    @Test func recapWithPhotosVisibleToEveryone() {
        let recap = makeRecap(photoCount: 2)
        #expect(recap.isVisibleOnMap(to: "stranger"))
        #expect(recap.isVisibleOnMap(to: nil))
    }

    @Test func emptyRecapHiddenWhenUserUnknown() {
        let recap = makeRecap(photoCount: 0)
        #expect(recap.isVisibleOnMap(to: nil) == false)
    }

    // MARK: - Identity

    @Test func recapsWithSameIdAndPhotoCountAreEqual() {
        let first = makeRecap()
        var second = makeRecap(attendeeIds: ["other"])
        second.title = "Different title"
        #expect(first == second)
    }

    @Test func photoCountChangeBreaksEquality() {
        let first = makeRecap(photoCount: 0)
        let second = makeRecap(photoCount: 3)
        #expect(first != second)
    }
}
