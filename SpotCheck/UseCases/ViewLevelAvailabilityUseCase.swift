import Foundation

struct ViewLevelAvailabilityUseCase {
    let repository: any StudySpaceRepository
    let widget: any WidgetRefreshing
    let snapshot: any AvailabilitySnapshotWriting

    /// Every level of `building`, each with its free seats counted and stamped with `now`.
    ///
    /// A successful read also replaces the levels in the snapshot the widget reads, so the widget
    /// shows the building the student last viewed, and then reloads the widget.
    func execute(building: CampusBuilding, now: Date) async throws -> [LevelAvailability] {
        let levels = try await repository.levels(inBuilding: building.id, at: now)
        let availabilities = levels.map { availability(of: $0, now: now) }

        snapshot.write(
            levels: availabilities.map {
                AvailabilitySnapshot.LevelCount(
                    id: $0.id,
                    number: $0.level.number,
                    free: $0.free,
                    total: $0.total
                )
            },
            inBuilding: building.name,
            readAt: now
        )
        widget.reloadAll()
        return availabilities
    }

    /// Free and total seats for one level the caller has already read, stamped with `now`.
    /// A seat is free when it has no check-in active at `now`, so an expired check-in does not count.
    func availability(of level: StudyLevel, now: Date) -> LevelAvailability {
        let seats = level.zones.flatMap(\.seats)
        let free = seats.filter { $0.activeCheckIn(at: now) == nil }.count
        return LevelAvailability(level: level, free: free, total: seats.count, lastUpdatedAt: now)
    }
}
