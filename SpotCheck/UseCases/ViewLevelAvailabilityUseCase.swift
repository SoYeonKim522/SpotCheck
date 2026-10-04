import Foundation

struct ViewLevelAvailabilityUseCase {
    let repository: any StudySpaceRepository

    /// Every level of a building, each with its free seats counted and stamped with `now`.
    /// A failed read is a network failure, not a domain error, so it is left to propagate.
    func execute(buildingID: UUID, now: Date) async throws -> [LevelAvailability] {
        let levels = try await repository.levels(inBuilding: buildingID, at: now)
        return levels.map { availability(of: $0, now: now) }
    }

    /// Free and total seats for one level the caller has already read, stamped with `now`.
    /// A seat is free when it has no check-in active at `now`, so an expired check-in does not count.
    func availability(of level: StudyLevel, now: Date) -> LevelAvailability {
        let seats = level.zones.flatMap(\.seats)
        let free = seats.filter { $0.activeCheckIn(at: now) == nil }.count
        return LevelAvailability(level: level, free: free, total: seats.count, lastUpdatedAt: now)
    }
}
