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
        let identifier = occupant.value
        var descriptor = FetchDescriptor<SeatCheckIn>(
            predicate: #Predicate {
                $0.occupantIdentifier == identifier && $0.releasedAt == nil && $0.expiresAt > moment
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func add(_ checkIn: SeatCheckIn) {
        context.insert(checkIn)
    }

    func save() throws {
        try context.save()
    }
}
