import Foundation

/// The number of free seats on one level at a single moment.
///
/// The count is calculated from the level's check-ins rather than stored.
/// `free` does not include seats held by a check-in that has not expired yet.
/// `lastUpdatedAt` records when the numbers were read. It is kept in the same type
/// so that a count is always shown with the time it was read.
struct LevelAvailability: Identifiable, Hashable {
    let level: StudyLevel
    let free: Int
    let total: Int
    let lastUpdatedAt: Date

    var id: UUID {
        level.id
    }

    /// How full this level is. See `LevelFullness`.
    var fullness: LevelFullness {
        LevelFullness(free: free, total: total)
    }
}
