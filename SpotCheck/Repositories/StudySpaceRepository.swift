//
//  StudySpaceRepository.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 10/9/2026.
//

import Foundation

/// Defines how the app accesses study spaces and check-ins stored on the device.
///
/// Use cases depend on this protocol instead of SwiftData, so tests can provide
/// their own store. It only stores data that the app cannot calculate itself.
/// Seat availability is not stored because it is calculated from the active
/// check-ins for each seat.
protocol StudySpaceRepository {
    func buildings() throws -> [CampusBuilding]
    func activeCheckIn(for occupant: OccupantIdentifier, at moment: Date) throws -> SeatCheckIn?
    func add(_ checkIn: SeatCheckIn) throws
    func update(_ checkIn: SeatCheckIn) throws
}
