import Foundation
import Testing
@testable import SpotCheck

@MainActor
struct ExtendHoldUseCaseTests {
    let repository = MockStudySpaceRepository()
    let reminders = MockReminderScheduler()
    let widget = MockWidgetRefresher()
    let snapshot = MockSnapshotWriter()

    var useCase: ExtendHoldUseCase {
        ExtendHoldUseCase(
            repository: repository,
            reminders: reminders,
            widget: widget,
            snapshot: snapshot
        )
    }

    @Test func extendingAHoldAddsAnotherHour() async throws {
        let occupant = TestData.occupant()
        let checkIn = TestData.checkIn(by: occupant)
        let hold = TestData.hold(of: checkIn)
        repository.seatHolds = [hold]

        let extended = try await useCase.execute(
            hold: hold,
            occupant: occupant,
            now: TestData.now.addingTimeInterval(10 * 60)
        )

        #expect(extended.checkIn.expiresAt == TestData.now.addingTimeInterval(2 * 60 * 60))
        #expect(extended.checkIn.checkedInAt == checkIn.checkedInAt)
        #expect(repository.updatedCheckIns.map(\.expiresAt) == [extended.checkIn.expiresAt])
    }

    @Test func extendingAHoldAddsToTheCurrentExpiryRatherThanRestartingFromNow() async throws {
        let occupant = TestData.occupant()
        let hold = TestData.hold(of: TestData.checkIn(by: occupant))
        repository.seatHolds = [hold]
        let tenMinutesLeft = TestData.now.addingTimeInterval(50 * 60)

        let extended = try await useCase.execute(hold: hold, occupant: occupant, now: tenMinutesLeft)

        #expect(extended.checkIn.expiresAt == TestData.now.addingTimeInterval(2 * 60 * 60))
        #expect(extended.checkIn.expiresAt != tenMinutesLeft.addingTimeInterval(60 * 60))
    }

    @Test func aHoldCannotBeExtendedPastThreeHours() async throws {
        let occupant = TestData.occupant()
        let hold = TestData.hold(
            of: TestData.checkIn(by: occupant, expiresAt: TestData.now.addingTimeInterval(2.5 * 60 * 60))
        )
        repository.seatHolds = [hold]

        let extended = try await useCase.execute(
            hold: hold,
            occupant: occupant,
            now: TestData.now.addingTimeInterval(2 * 60 * 60)
        )

        #expect(extended.checkIn.expiresAt == TestData.now.addingTimeInterval(3 * 60 * 60))
    }

    @Test func aHoldAlreadyAtThreeHoursCannotBeExtended() async throws {
        let occupant = TestData.occupant()
        let hold = TestData.hold(
            of: TestData.checkIn(by: occupant, expiresAt: TestData.now.addingTimeInterval(3 * 60 * 60))
        )
        repository.seatHolds = [hold]

        await #expect(throws: ExtendHoldError.alreadyAtMaximum) {
            try await useCase.execute(
                hold: hold,
                occupant: occupant,
                now: TestData.now.addingTimeInterval(2.5 * 60 * 60)
            )
        }
        #expect(repository.updatedCheckIns.isEmpty)
    }

    @Test func anExpiredHoldCannotBeExtended() async throws {
        let occupant = TestData.occupant()
        let hold = TestData.hold(of: TestData.checkIn(by: occupant))
        repository.seatHolds = [hold]

        await #expect(throws: ExtendHoldError.holdHasExpired) {
            try await useCase.execute(
                hold: hold,
                occupant: occupant,
                now: TestData.now.addingTimeInterval(2 * 60 * 60)
            )
        }
        #expect(repository.updatedCheckIns.isEmpty)
    }

    @Test func aHoldCannotBeExtendedAtTheMomentItExpires() async throws {
        let occupant = TestData.occupant()
        let checkIn = TestData.checkIn(by: occupant)
        let hold = TestData.hold(of: checkIn)
        repository.seatHolds = [hold]

        await #expect(throws: ExtendHoldError.holdHasExpired) {
            try await useCase.execute(hold: hold, occupant: occupant, now: checkIn.expiresAt)
        }
        #expect(repository.updatedCheckIns.isEmpty)
    }

    @Test func anotherOccupantCannotExtendSomeoneElsesHold() async throws {
        let hold = TestData.hold(of: TestData.checkIn(by: TestData.occupant()))
        repository.seatHolds = [hold]

        await #expect(throws: ExtendHoldError.notTheHolder) {
            try await useCase.execute(hold: hold, occupant: TestData.occupant(), now: TestData.now)
        }
        #expect(repository.updatedCheckIns.isEmpty)
        #expect(reminders.scheduledHolds.isEmpty)
    }

    @Test func extendingAHoldReschedulesTheReminderAndReloadsTheWidget() async throws {
        let occupant = TestData.occupant()
        let hold = TestData.hold(of: TestData.checkIn(by: occupant))
        repository.seatHolds = [hold]

        let extended = try await useCase.execute(hold: hold, occupant: occupant, now: TestData.now)

        #expect(reminders.scheduledHolds == [extended])
        #expect(widget.reloadCount == 1)
    }

    @Test func extendingAHoldWritesTheNewExpiryToTheSnapshot() async throws {
        let occupant = TestData.occupant()
        let hold = TestData.hold(
            of: TestData.checkIn(by: occupant),
            seatLabel: "5R4",
            zoneName: "Reading Room",
            levelNumber: 5
        )
        repository.seatHolds = [hold]

        _ = try await useCase.execute(hold: hold, occupant: occupant, now: TestData.now)

        let expected = AvailabilitySnapshot.HeldSeat(
            seatLabel: "5R4",
            zoneName: "Reading Room",
            levelNumber: 5,
            expiresAt: TestData.now.addingTimeInterval(2 * 60 * 60)
        )
        #expect(snapshot.writtenHolds == [expected])
    }
}
