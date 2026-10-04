import Foundation
import Testing
@testable import SpotCheck

@MainActor
struct ReleaseSeatUseCaseTests {
    let repository = MockStudySpaceRepository()
    let reminders = MockReminderScheduler()
    let widget = MockWidgetRefresher()
    let snapshot = MockSnapshotWriter()

    var useCase: ReleaseSeatUseCase {
        ReleaseSeatUseCase(
            repository: repository,
            reminders: reminders,
            widget: widget,
            snapshot: snapshot
        )
    }

    @Test func releasingASeatMarksItReleasedAtThatMoment() async throws {
        let occupant = TestData.occupant()
        let checkIn = TestData.checkIn(by: occupant)
        repository.seatHolds = [TestData.hold(of: checkIn)]
        let releasedAt = TestData.now.addingTimeInterval(10 * 60)

        try await useCase.execute(checkIn: checkIn, occupant: occupant, now: releasedAt)

        #expect(repository.updatedCheckIns.map(\.id) == [checkIn.id])
        #expect(repository.updatedCheckIns.first?.releasedAt == releasedAt)
    }

    @Test func releasingASeatCancelsTheReminderAndReloadsTheWidget() async throws {
        let occupant = TestData.occupant()
        let checkIn = TestData.checkIn(by: occupant)
        repository.seatHolds = [TestData.hold(of: checkIn)]

        try await useCase.execute(checkIn: checkIn, occupant: occupant, now: TestData.now)

        #expect(reminders.cancelledCheckInIDs == [checkIn.id])
        #expect(widget.reloadCount == 1)
    }

    @Test func releasingASeatClearsTheHeldSeatFromTheSnapshot() async throws {
        let occupant = TestData.occupant()
        let checkIn = TestData.checkIn(by: occupant)
        repository.seatHolds = [TestData.hold(of: checkIn)]

        try await useCase.execute(checkIn: checkIn, occupant: occupant, now: TestData.now)

        #expect(snapshot.writtenHolds == [nil])
    }

    @Test func anotherOccupantCannotReleaseSomeoneElsesSeat() async throws {
        let checkIn = TestData.checkIn(by: TestData.occupant())
        repository.seatHolds = [TestData.hold(of: checkIn)]

        await #expect(throws: ReleaseSeatError.notTheHolder) {
            try await useCase.execute(checkIn: checkIn, occupant: TestData.occupant(), now: TestData.now)
        }
        #expect(repository.updatedCheckIns.isEmpty)
        #expect(reminders.cancelledCheckInIDs.isEmpty)
    }

    @Test func aSeatThatWasAlreadyReleasedCannotBeReleasedAgain() async throws {
        let occupant = TestData.occupant()
        let checkIn = TestData.checkIn(by: occupant, releasedAt: TestData.now.addingTimeInterval(10 * 60))
        repository.seatHolds = [TestData.hold(of: checkIn)]

        await #expect(throws: ReleaseSeatError.seatWasAlreadyReleased) {
            try await useCase.execute(
                checkIn: checkIn,
                occupant: occupant,
                now: TestData.now.addingTimeInterval(20 * 60)
            )
        }
        #expect(repository.updatedCheckIns.isEmpty)
    }

    @Test func aHoldThatHasExpiredCannotBeReleased() async throws {
        let occupant = TestData.occupant()
        let checkIn = TestData.checkIn(by: occupant)
        repository.seatHolds = [TestData.hold(of: checkIn)]

        await #expect(throws: ReleaseSeatError.holdHasExpired) {
            try await useCase.execute(
                checkIn: checkIn,
                occupant: occupant,
                now: TestData.now.addingTimeInterval(2 * 60 * 60)
            )
        }
        #expect(repository.updatedCheckIns.isEmpty)
        #expect(snapshot.writtenHolds.isEmpty)
    }

    @Test func aHoldCanBeReleasedJustBeforeItExpires() async throws {
        let occupant = TestData.occupant()
        let checkIn = TestData.checkIn(by: occupant)
        repository.seatHolds = [TestData.hold(of: checkIn)]
        let oneSecondBeforeExpiry = checkIn.expiresAt.addingTimeInterval(-1)

        try await useCase.execute(checkIn: checkIn, occupant: occupant, now: oneSecondBeforeExpiry)

        #expect(repository.updatedCheckIns.first?.releasedAt == oneSecondBeforeExpiry)
    }

    @Test func aHoldCannotBeReleasedAtTheMomentItExpires() async throws {
        let occupant = TestData.occupant()
        let checkIn = TestData.checkIn(by: occupant)
        repository.seatHolds = [TestData.hold(of: checkIn)]

        await #expect(throws: ReleaseSeatError.holdHasExpired) {
            try await useCase.execute(checkIn: checkIn, occupant: occupant, now: checkIn.expiresAt)
        }
        #expect(repository.updatedCheckIns.isEmpty)
    }
}
