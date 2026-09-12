//
//  ViewLevelAvailabilityUseCase.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 12/9/2026.
//

import Foundation

struct ViewLevelAvailabilityUseCase {
    func execute(building: CampusBuilding, now: Date) -> [LevelAvailability] {
        building.levels
            .sorted { $0.number < $1.number }
            .map { level in
                let seats = level.zones.flatMap(\.seats)
                return LevelAvailability(
                    levelNumber: level.number,
                    free: seats.filter { $0.activeCheckIn(at: now) == nil }.count,
                    total: level.capacity,
                    lastUpdatedAt: seats.flatMap(\.checkIns)
                        .map { $0.releasedAt ?? $0.checkedInAt }
                        .max()
                )
            }
    }
}
