import Foundation

struct ExtendHoldUseCase {
    let repository: any StudySpaceRepository
    let reminders: any ExpiryReminderScheduling
    let widget: any WidgetRefreshing
    let snapshot: any AvailabilitySnapshotWriting

    /// Keeps a seat for another hour by moving its expiry forward, up to the three-hour cap.
    ///
    /// The extra hour is added to the current expiry rather than restarting the clock from now, so
    /// an extension never shortens a hold. Once the expiry reaches `checkedInAt + maximumDuration`
    /// it stops at the cap, and a hold already at the cap cannot be extended again. Moving the
    /// expiry reschedules the reminder and updates the snapshot the widget reads.
    func execute(hold: SeatHold, now: Date) async throws -> SeatHold {
        let checkIn = hold.checkIn
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
            expiresAt: extended.expiresAt
        ))
        widget.reloadAll()
        return extendedHold
    }
}

enum ExtendHoldError: LocalizedError {
    case holdHasExpired
    case alreadyAtMaximum

    var errorDescription: String? {
        switch self {
        case .holdHasExpired:
            return "Your hold on this seat has ended."
        case .alreadyAtMaximum:
            return "You've held this seat for the full three hours."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .holdHasExpired:
            return "Check in again to keep studying here."
        case .alreadyAtMaximum:
            return "Release it so someone else can use it."
        }
    }
}
