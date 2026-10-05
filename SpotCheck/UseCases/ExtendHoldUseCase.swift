import Foundation

struct ExtendHoldUseCase {
    let repository: any StudySpaceRepository
    let reminders: any ExpiryReminderScheduling
    let widget: any WidgetRefreshing
    let snapshot: any AvailabilitySnapshotWriting

    /// Keeps a seat for another hour by moving its expiry forward, up to the three-hour cap.
    ///
    /// The extra hour is added to the current expiry rather than restarting the clock from now, so
    /// an extension does not shorten a hold. Once the expiry reaches `checkedInAt + maximumDuration`
    /// it stops at the cap, and a hold already at the cap cannot be extended again.
    /// After the expiry moves, the use case reschedules the reminder and updates the snapshot the
    /// widget reads. Only the person who made the check-in can extend it.
    func execute(hold: SeatHold, occupant: OccupantIdentifier, now: Date) async throws -> SeatHold {
        let checkIn = hold.checkIn
        guard checkIn.checkedInBy == occupant else {
            throw ExtendHoldError.notTheHolder
        }
        guard checkIn.isActive(at: now) else {
            throw ExtendHoldError.holdHasExpired
        }
        let cap = SeatHoldPolicy.latestExpiry(for: checkIn.checkedInAt)
        guard checkIn.expiresAt < cap else {
            throw ExtendHoldError.alreadyAtMaximum
        }

        var extended = checkIn
        extended.expiresAt = min(checkIn.expiresAt.addingTimeInterval(SeatHoldPolicy.duration), cap)
        try await repository.update(extended)

        let extendedHold = SeatHold(
            checkIn: extended,
            seatLabel: hold.seatLabel,
            zoneName: hold.zoneName,
            levelNumber: hold.levelNumber,
            buildingName: hold.buildingName
        )
        reminders.scheduleReminder(for: extendedHold)
        snapshot.write(hold: AvailabilitySnapshot.HeldSeat(
            seatLabel: extendedHold.seatLabel,
            zoneName: extendedHold.zoneName,
            levelNumber: extendedHold.levelNumber,
            buildingName: extendedHold.buildingName,
            checkedInAt: extended.checkedInAt,
            expiresAt: extended.expiresAt
        ))
        widget.reloadAll()
        return extendedHold
    }
}

enum ExtendHoldError: LocalizedError {
    case notTheHolder
    case holdHasExpired
    case alreadyAtMaximum

    var errorDescription: String? {
        switch self {
        case .notTheHolder:
            return "This seat is held by someone else."
        case .holdHasExpired:
            return "Your hold on this seat has ended."
        case .alreadyAtMaximum:
            return "A seat can't be held for more than \(SeatHoldPolicy.maximumDurationText) at a time."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notTheHolder:
            return "Only the person who checked in can extend it."
        case .holdHasExpired:
            return "Check in again to keep studying here."
        case .alreadyAtMaximum:
            return "Release this seat, then check in again if you still need it."
        }
    }
}
