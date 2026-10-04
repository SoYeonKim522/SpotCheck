import Foundation
import Testing
@testable import SpotCheck

@MainActor
struct CheckIntoSeatUseCaseTests {
    let repository = MockStudySpaceRepository()
    let reminders = MockReminderScheduler()
    let widget = MockWidgetRefresher()
    let snapshot = MockSnapshotWriter()

    var useCase: CheckIntoSeatUseCase {
        CheckIntoSeatUseCase(
            repository: repository,
            reminders: reminders,
            widget: widget,
            snapshot: snapshot
        )
    }

    @Test func checkingIntoAFreeSeatSucceeds() async throws {
        let occupant = TestData.occupant()
        let seat = TestData.seat()

        let hold = try await useCase.execute(seat: seat, occupant: occupant, now: TestData.now)

        #expect(hold.checkIn.seatID == seat.id)
        #expect(hold.checkIn.checkedInBy == occupant)
        #expect(repository.addedCheckIns == [hold.checkIn])
    }

    @Test func aCheckInExpiresOneHourAfterItWasMade() async throws {
        let hold = try await useCase.execute(seat: TestData.seat(), occupant: TestData.occupant(), now: TestData.now)

        #expect(hold.checkIn.checkedInAt == TestData.now)
        #expect(hold.checkIn.expiresAt == TestData.now.addingTimeInterval(60 * 60))
    }

    @Test func checkingIntoATakenSeatIsRejected() async throws {
        let seat = TestData.seat()
        repository.seatHolds = [TestData.hold(of: TestData.checkIn(seatID: seat.id))]

        await #expect {
            try await useCase.execute(seat: seat, occupant: TestData.occupant(), now: TestData.now)
        } throws: { error in
            guard case CheckIntoSeatError.seatIsTaken = error else { return false }
            return true
        }
        #expect(repository.addedCheckIns.isEmpty)
    }

    @Test func someoneAlreadyHoldingASeatCannotClaimAnother() async throws {
        let occupant = TestData.occupant()
        repository.seatHolds = [TestData.hold(of: TestData.checkIn(by: occupant))]

        await #expect {
            try await useCase.execute(seat: TestData.seat(), occupant: occupant, now: TestData.now)
        } throws: { error in
            guard case CheckIntoSeatError.occupantAlreadyHoldsASeat = error else { return false }
            return true
        }
        #expect(repository.addedCheckIns.isEmpty)
    }

    @Test func theAlreadyHoldingErrorNamesTheSeatSheIsIn() async throws {
        let occupant = TestData.occupant()
        repository.seatHolds = [
            TestData.hold(of: TestData.checkIn(by: occupant), seatLabel: "5R4", levelNumber: 5)
        ]

        await #expect {
            try await useCase.execute(seat: TestData.seat(), occupant: occupant, now: TestData.now)
        } throws: { error in
            error.localizedDescription == "You're already checked in on Level 5, seat 5R4."
        }
    }

    @Test func theirOwnSeatIsReportedBeforeATakenSeat() async throws {
        let occupant = TestData.occupant()
        let takenSeat = TestData.seat()
        repository.seatHolds = [
            TestData.hold(of: TestData.checkIn(by: occupant)),
            TestData.hold(of: TestData.checkIn(seatID: takenSeat.id))
        ]

        await #expect {
            try await useCase.execute(seat: takenSeat, occupant: occupant, now: TestData.now)
        } throws: { error in
            guard case CheckIntoSeatError.occupantAlreadyHoldsASeat = error else { return false }
            return true
        }
    }

    @Test func checkingInSchedulesAReminderAndReloadsTheWidget() async throws {
        let hold = try await useCase.execute(seat: TestData.seat(), occupant: TestData.occupant(), now: TestData.now)

        #expect(reminders.scheduledHolds == [hold])
        #expect(widget.reloadCount == 1)
    }

    @Test func checkingInWritesTheHeldSeatToTheSnapshot() async throws {
        repository.locationOfNewCheckIns = (
            seatLabel: "5R4", zoneName: "Reading Room", levelNumber: 5, buildingName: "Building 2"
        )

        _ = try await useCase.execute(seat: TestData.seat(), occupant: TestData.occupant(), now: TestData.now)

        let expected = AvailabilitySnapshot.HeldSeat(
            seatLabel: "5R4",
            zoneName: "Reading Room",
            levelNumber: 5,
            expiresAt: TestData.now.addingTimeInterval(60 * 60)
        )
        #expect(snapshot.writtenHolds == [expected])
    }
}
