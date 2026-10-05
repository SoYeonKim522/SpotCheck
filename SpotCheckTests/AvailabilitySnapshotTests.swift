import Foundation
import Testing
@testable import SpotCheck

struct AvailabilitySnapshotTests {
    private func snapshot(readAt: Date, expiresAt: Date? = nil) -> AvailabilitySnapshot {
        AvailabilitySnapshot(
            buildingName: "Building 2",
            levels: [],
            hold: expiresAt.map {
                AvailabilitySnapshot.HeldSeat(
                    seatLabel: "6L3",
                    zoneName: "Library",
                    levelNumber: 6,
                    buildingName: "Building 2",
                    checkedInAt: readAt,
                    expiresAt: $0
                )
            },
            readAt: readAt
        )
    }

    @Test func theWidgetChangesAtTheReminderAndAtTheMomentTheHoldEnds() {
        let expiresAt = TestData.now.addingTimeInterval(SeatHoldPolicy.duration)
        let changes = snapshot(readAt: TestData.now, expiresAt: expiresAt).displayChanges(from: TestData.now)

        #expect(changes == [
            TestData.now.addingTimeInterval(AvailabilitySnapshot.freshnessWindow),
            expiresAt.addingTimeInterval(-SeatHoldPolicy.reminderLead),
            expiresAt
        ])
    }

    @Test func theWidgetChangesWhenTheCountsTurnStale() {
        let changes = snapshot(readAt: TestData.now).displayChanges(from: TestData.now)

        #expect(changes == [TestData.now.addingTimeInterval(AvailabilitySnapshot.freshnessWindow)])
    }

    @Test func momentsThatHavePassedAreLeftOut() {
        let expiresAt = TestData.now.addingTimeInterval(SeatHoldPolicy.duration)
        let afterTheReminder = expiresAt.addingTimeInterval(-60)
        let changes = snapshot(readAt: TestData.now, expiresAt: expiresAt).displayChanges(from: afterTheReminder)

        #expect(changes == [expiresAt])
    }

    @Test func countsThatWereNeverReadHaveNoStaleMomentToWaitFor() {
        let changes = snapshot(readAt: .distantPast).displayChanges(from: TestData.now)

        #expect(changes.isEmpty)
    }
}
