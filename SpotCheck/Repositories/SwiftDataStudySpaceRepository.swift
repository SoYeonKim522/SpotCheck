//
//  SwiftDataStudySpaceRepository.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 10/9/2026.
//

import Foundation
import SwiftData

struct SwiftDataStudySpaceRepository: StudySpaceRepository {
    let context: ModelContext

    func buildings() throws -> [CampusBuilding] {
        try context.fetch(FetchDescriptor<CampusBuilding>())
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func activeCheckIn(for occupant: OccupantIdentifier, at moment: Date) throws -> SeatCheckIn? {
        let unexpired = FetchDescriptor<SeatCheckIn>(
            predicate: #Predicate { $0.releasedAt == nil && $0.expiresAt > moment }
        )
        return try context.fetch(unexpired).first { $0.checkedInBy == occupant }
    }

    func add(_ checkIn: SeatCheckIn) throws {
        context.insert(checkIn)
        try context.save()
    }

    func save() throws {
        try context.save()
    }
}
