import Foundation

struct CheckIntoSeatUseCase {
    let repository: any StudySpaceRepository
    let reminders: any ExpiryReminderScheduling
    let widget: any WidgetRefreshing
    let snapshot: any AvailabilitySnapshotWriting

    /// Checks `occupant` into `seat` and returns the seat they now hold.
    ///
    /// A person already holding a seat is told about their own seat before the seat they tapped is
    /// checked, so they hear about the one they can act on. The expiry is set one `duration` from
    /// `now`. After the check-in is added, the hold is read back so the reminder and the widget get
    /// the seat's location, which the check-in on its own does not carry.
    func execute(seat: StudySeat, occupant: OccupantIdentifier, now: Date) async throws -> SeatHold {
        // TODO: if the occupant already holds a seat, throw occupantAlreadyHoldsASeat(thatHold)
        // TODO: if the seat is already taken, throw seatIsTaken

        let checkIn = SeatCheckIn(
            id: UUID(),
            seatID: seat.id,
            checkedInBy: occupant,
            checkedInAt: now,
            expiresAt: now.addingTimeInterval(SeatHoldPolicy.duration),
            releasedAt: nil
        )
        try await repository.add(checkIn)

        // TODO: the add landed but the read back can still fail or return nothing. Decide how to
        // surface a write that succeeded without a hold to show.
        guard let hold = try await repository.activeHold(for: occupant, at: now) else {
            throw CheckIntoSeatError.seatIsTaken
        }

        reminders.scheduleReminder(for: hold)
        snapshot.write(hold: AvailabilitySnapshot.HeldSeat(
            seatLabel: hold.seatLabel,
            zoneName: hold.zoneName,
            levelNumber: hold.levelNumber,
            expiresAt: hold.checkIn.expiresAt
        ))
        widget.reloadAll()
        return hold
    }
}

enum CheckIntoSeatError: LocalizedError {
    case occupantAlreadyHoldsASeat(SeatHold)
    case seatIsTaken

    var errorDescription: String? {
        // TODO
        nil
    }

    var recoverySuggestion: String? {
        // TODO
        nil
    }
}
