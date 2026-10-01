import Foundation

/// A single seat that a student can check in to.
///
/// A seat is considered free when it has no active check-ins.
/// The app checks the seat's current check-ins whenever it needs to know
/// whether the seat is available, rather than storing its availability separately.
/// This means an expired check-in frees the seat automatically, without needing
/// a timer or a separate cleanup process.
struct StudySeat: Identifiable, Hashable {
    let id: UUID
    let zoneID: UUID
    let label: String
    let isByWindow: Bool
    let hasComputer: Bool
    let hasPowerOutlet: Bool
    let hasPartition: Bool
    let isSharedTable: Bool
    let checkIns: [SeatCheckIn]

    func activeCheckIn(at moment: Date) -> SeatCheckIn? {
        checkIns.first { $0.isActive(at: moment) }
    }
}
