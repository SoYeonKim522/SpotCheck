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
            .sorted { $0.displayOrder < $1.displayOrder }
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

    func add(_ checkIn: SeatCheckIn) throws {
        context.insert(checkIn)
        try context.save()
    }

    func update(_ checkIn: SeatCheckIn) throws {
        try context.save()
    }
}
