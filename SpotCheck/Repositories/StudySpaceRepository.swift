//
//  StudySpaceRepository.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 10/9/2026.
//

import Foundation

protocol StudySpaceRepository {
    func buildings() throws -> [CampusBuilding]
    func activeCheckIn(for occupant: OccupantIdentifier, at moment: Date) throws -> SeatCheckIn?
    func add(_ checkIn: SeatCheckIn) throws
    func save() throws
}
