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
        if let held = try repository.activeCheckIn(for: occupant, at: now) {
            throw CheckIntoSeatError.occupantAlreadyHoldsASeat(heldSeat: held.seat)
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
        try repository.add(checkIn)
        return checkIn
    }
}

enum CheckIntoSeatError: LocalizedError {
    case occupantAlreadyHoldsASeat(heldSeat: StudySeat?)
    case seatIsTaken

    var errorDescription: String? {
        switch self {
        case let .occupantAlreadyHoldsASeat(heldSeat):
            guard let heldSeat, let level = heldSeat.zone?.level else {
                return "You already hold a seat."
            }
            return "You're already checked in on Level \(level.number), seat \(heldSeat.label)."
        case .seatIsTaken:
            return "Someone else checked in to this seat first."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .occupantAlreadyHoldsASeat: "Release that seat first."
        case .seatIsTaken: "Refresh to see which seats are free now."
        }
    }
}
