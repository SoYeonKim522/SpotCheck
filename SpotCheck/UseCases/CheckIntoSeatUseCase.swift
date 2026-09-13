//
//  CheckIntoSeatUseCase.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 12/9/2026.
//

import Foundation

struct CheckIntoSeatUseCase {
    let repository: StudySpaceRepository

    func execute(
        seat: StudySeat,
        occupant: OccupantIdentifier,
        now: Date
    ) throws -> SeatCheckIn {
        guard try repository.activeCheckIn(for: occupant, at: now) == nil else {
            throw CheckIntoSeatError.occupantAlreadyHoldsASeat
        }
        guard seat.activeCheckIn(at: now) == nil else {
            throw CheckIntoSeatError.seatIsTaken
        }

        let checkIn = SeatCheckIn(
            checkedInBy: occupant,
            seat: seat,
            checkedInAt: now,
            expiresAt: now.addingTimeInterval(SeatHoldPolicy.duration)
        )
        repository.add(checkIn)
        try repository.save()
        return checkIn
    }
}

enum CheckIntoSeatError: LocalizedError {
    case occupantAlreadyHoldsASeat
    case seatIsTaken

    var errorDescription: String? {
        switch self {
        case .occupantAlreadyHoldsASeat: "You already hold a seat."
        case .seatIsTaken: "Someone else checked in to this seat first."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .occupantAlreadyHoldsASeat: "Release the seat you are holding, then check in here."
        case .seatIsTaken: "Refresh to see which seats are free now."
        }
    }
}
