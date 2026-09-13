//
//  ExtendHoldUseCase.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 13/9/2026.
//

import Foundation

struct ExtendHoldUseCase {
    let repository: StudySpaceRepository

    func execute(
        checkIn: SeatCheckIn,
        occupant: OccupantIdentifier,
        now: Date
    ) throws {
        guard checkIn.checkedInBy == occupant else {
            throw ExtendHoldError.checkInBelongsToAnotherOccupant
        }
        guard checkIn.releasedAt == nil else {
            throw ExtendHoldError.seatWasAlreadyReleased
        }
        guard now < checkIn.expiresAt else {
            throw ExtendHoldError.holdHasAlreadyExpired
        }

        checkIn.expiresAt = now.addingTimeInterval(SeatHoldPolicy.duration)
        try repository.save()
    }
}

enum ExtendHoldError: Error {
    case checkInBelongsToAnotherOccupant
    case seatWasAlreadyReleased
    case holdHasAlreadyExpired
}
