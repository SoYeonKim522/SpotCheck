import Foundation

/// Defines how the app reads study spaces and writes check-ins.
///
/// Use cases depend on this protocol instead of Supabase, so tests can provide their own store.
/// It only holds data that the app cannot calculate itself. Seat availability is not stored
/// because it is calculated from the active check-ins for each seat.
///
/// Every method is async and can fail, because the store is now shared and reached over the
/// network. Each read takes the moment it is made, so what counts as an active check-in is
/// decided by the caller rather than by the server's clock.
protocol StudySpaceRepository {
    /// The buildings a student can choose between, in the order they should be shown.
    func buildings() async throws -> [CampusBuilding]

    /// Every level of a building in number order, with its zones, seats and the check-ins active at `moment`.
    /// The caller(ViewLevelAvailabilityUseCase) counts the free seats.
    func levels(inBuilding buildingID: UUID, at moment: Date) async throws -> [StudyLevel]

    /// The zones of one level with their seats, carrying only the check-ins active at `moment`.
    func zones(onLevel levelID: UUID, at moment: Date) async throws -> [StudyZone]

    /// The seat this person is holding at `moment`, or `nil` if they are not holding one.
    func activeHold(for occupant: OccupantIdentifier, at moment: Date) async throws -> SeatHold?

    /// The seat's active check-in at `moment`, whoever holds it.
    func activeCheckIn(onSeat seatID: UUID, at moment: Date) async throws -> SeatCheckIn?

    /// The check-ins this person has finished by `moment`, newest first.
    /// A check-in is finished when it was released or has expired. Check-ins made by other people are not included.
    func history(for occupant: OccupantIdentifier, at moment: Date) async throws -> [SeatHold]

    func add(_ checkIn: SeatCheckIn) async throws

    func update(_ checkIn: SeatCheckIn) async throws
}
