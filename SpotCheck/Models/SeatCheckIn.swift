//
//  SeatCheckIn.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 8/9/2026.
//

import Foundation
import SwiftData

@Model
final class SeatCheckIn {
    var occupantIdentifier: String
    var seat: StudySeat?
    var checkedInAt: Date
    var expiresAt: Date
    var releasedAt: Date?

    var checkedInBy: OccupantIdentifier {
        OccupantIdentifier(value: occupantIdentifier)
    }

    init(checkedInBy: OccupantIdentifier, seat: StudySeat, checkedInAt: Date, expiresAt: Date) {
        self.occupantIdentifier = checkedInBy.value
        self.seat = seat
        self.checkedInAt = checkedInAt
        self.expiresAt = expiresAt
    }

    func isActive(at moment: Date) -> Bool {
        releasedAt == nil && moment < expiresAt
    }
}
