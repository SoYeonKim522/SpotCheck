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
        guard checkIn.releasedAt == nil else {
            throw ReleaseSeatError.seatWasAlreadyReleased
        }
        guard now < checkIn.expiresAt else {
            throw ReleaseSeatError.holdHasAlreadyExpired
        }

        checkIn.releasedAt = now
        try repository.save()
    }
}

enum ReleaseSeatError: LocalizedError {
    case checkInBelongsToAnotherOccupant
    case seatWasAlreadyReleased
    case holdHasAlreadyExpired

    var errorDescription: String? {
        switch self {
        case .checkInBelongsToAnotherOccupant: "Someone else holds this seat."
        case .seatWasAlreadyReleased: "You already released this seat."
        case .holdHasAlreadyExpired: "Your hold had already ended."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .checkInBelongsToAnotherOccupant: "You can only release a seat you checked in to."
        case .seatWasAlreadyReleased: "It is free for someone else now."
        case .holdHasAlreadyExpired: "Check in again if the seat is still free."
        }
    }
}
