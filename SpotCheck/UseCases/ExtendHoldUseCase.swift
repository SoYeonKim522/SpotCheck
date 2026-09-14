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

        let latestExpiry = SeatHoldPolicy.latestExpiry(for: checkIn.checkedInAt)
        guard checkIn.expiresAt < latestExpiry else {
            throw ExtendHoldError.holdIsAtItsMaximum
        }

        checkIn.expiresAt = min(
            checkIn.expiresAt.addingTimeInterval(SeatHoldPolicy.duration),
            latestExpiry
        )
        try repository.update(checkIn)
    }
}

enum ExtendHoldError: LocalizedError {
    case checkInBelongsToAnotherOccupant
    case seatWasAlreadyReleased
    case holdHasAlreadyExpired
    case holdIsAtItsMaximum

    var errorDescription: String? {
        switch self {
        case .checkInBelongsToAnotherOccupant: "Someone else holds this seat."
        case .seatWasAlreadyReleased: "You already released this seat."
        case .holdHasAlreadyExpired: "Your hold had already ended."
        case .holdIsAtItsMaximum: "A seat can be held for \(SeatHoldPolicy.maximumDurationText) at most."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .checkInBelongsToAnotherOccupant: "You can only extend your own hold."
        case .seatWasAlreadyReleased: "Check in again if the seat is still free."
        case .holdHasAlreadyExpired: "Check in again if the seat is still free."
        case .holdIsAtItsMaximum: "Check in again once this hold ends, if the seat is still free."
        }
    }
}
