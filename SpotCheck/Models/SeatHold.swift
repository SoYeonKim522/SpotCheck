import Foundation

/// A check-in together with where the seat is, in the words a student would use to walk to it.
///
/// Four places show the seat someone is holding and all four need the same thing: the hold bar,
/// the My check-in screen, the reminder, and the widget. Reading the check-in brings the
/// location with it so none of them has to read the building again.
struct SeatHold: Identifiable, Hashable {
    let checkIn: SeatCheckIn
    let seatLabel: String
    let zoneName: String
    let levelNumber: Int
    let buildingName: String

    var id: UUID {
        checkIn.id
    }
}
