import Foundation

struct ViewLevelAvailabilityUseCase {
    let repository: any StudySpaceRepository

    /// Every level of a building, each with its free seats counted and stamped with `now`.
    /// A failed read is a network failure, not a domain error, so it is left to propagate.
    func execute(buildingID: UUID, now: Date) async throws -> [LevelAvailability] {
        // TODO: read the levels, then count each one with `availability(of:now:)`
        []
    }

    /// Free and total seats for one level the caller has already read, stamped with `now`.
    /// A seat is free when it has no check-in active at `now`, so an expired check-in does not count.
    func availability(of level: StudyLevel, now: Date) -> LevelAvailability {
        // TODO: count the free seats across the level's zones
        LevelAvailability(level: level, free: 0, total: 0, lastUpdatedAt: now)
    }
}
