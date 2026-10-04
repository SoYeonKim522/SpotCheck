import Foundation

struct ReleaseSeatUseCase {
    let repository: any StudySpaceRepository
    let reminders: any ExpiryReminderScheduling
    let widget: any WidgetRefreshing
    let snapshot: any AvailabilitySnapshotWriting

    /// Releases the seat `checkIn` holds, so it becomes free for someone else.
    ///
    /// The check-in is passed in rather than just the occupant, so the ownership check is explicit:
    /// only the person who made a check-in can release it. Once released, the reminder is cancelled,
    /// the held seat is cleared from the snapshot the widget reads, and the widget is reloaded.
    func execute(checkIn: SeatCheckIn, occupant: OccupantIdentifier, now: Date) async throws {
        guard checkIn.checkedInBy == occupant else {
            throw ReleaseSeatError.notTheHolder
        }

        var released = checkIn
        released.releasedAt = now
        try await repository.update(released)

        reminders.cancelReminder(forCheckInID: checkIn.id)
        snapshot.write(hold: nil)
        widget.reloadAll()
    }
}

enum ReleaseSeatError: LocalizedError {
    case notTheHolder

    var errorDescription: String? {
        switch self {
        case .notTheHolder:
            return "This seat is held by someone else."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notTheHolder:
            return "Only the person who checked in can release it."
        }
    }
}
