//
//  CheckIntoSeatUseCase.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 12/9/2026.
//

import Foundation

struct CheckIntoSeatUseCase {
    let repository: StudySpaceRepository
    let holdDuration: TimeInterval = 60 * 60

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
            expiresAt: now.addingTimeInterval(holdDuration)
        )
        repository.add(checkIn)
        try repository.save()
        return checkIn
    }
}

enum CheckIntoSeatError: Error {
    case occupantAlreadyHoldsASeat
    case seatIsTaken
}
