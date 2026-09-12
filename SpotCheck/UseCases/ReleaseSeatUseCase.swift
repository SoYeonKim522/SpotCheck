//
//  ReleaseSeatUseCase.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 12/9/2026.
//

import Foundation

struct ReleaseSeatUseCase {
    let repository: StudySpaceRepository

    func execute(
        checkIn: SeatCheckIn,
        occupant: OccupantIdentifier,
        now: Date
    ) throws {
        guard checkIn.checkedInBy == occupant else {
            throw ReleaseSeatError.checkInBelongsToAnotherOccupant
        }
        guard checkIn.isActive(at: now) else {
            throw ReleaseSeatError.checkInIsNoLongerActive
        }

        checkIn.releasedAt = now
        try repository.save()
    }
}

enum ReleaseSeatError: Error {
    case checkInBelongsToAnotherOccupant
    case checkInIsNoLongerActive
}
