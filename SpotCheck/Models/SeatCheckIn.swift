import Foundation

/// A student's claim on a seat. Availability counts are calculated from these records.
///
/// A check-in expires after `SeatHoldPolicy.duration` and can be extended up to
/// `SeatHoldPolicy.maximumDuration` in a single check-in.
/// Students can also give up the seat early.
/// When the student leaves the seat, `releasedAt` records when the check-in ended.
/// Only the student who made the check-in can release it.
struct SeatCheckIn: Identifiable, Hashable {
    let id: UUID
    let seatID: UUID
    let checkedInBy: OccupantIdentifier
    let checkedInAt: Date
    var expiresAt: Date
    var releasedAt: Date?

    func isActive(at moment: Date) -> Bool {
        releasedAt == nil && moment < expiresAt
    }

    /// How long the student was at the seat.
    ///
    /// It ends when the student released the seat. If they did not, the app does not know when
    /// they left, so it counts until the check-in expired.
    var timeAtSeat: TimeInterval {
        (releasedAt ?? expiresAt).timeIntervalSince(checkedInAt)
    }

    /// The time at the seat in whole minutes, rounded to the nearest minute.
    /// Screens show this value, so a total made from it matches the rows it adds up.
    var minutesAtSeat: Int {
        Int((timeAtSeat / 60).rounded())
    }
}
