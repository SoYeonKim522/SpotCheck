//
//  SeatCheckIn.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 8/9/2026.
//

import Foundation
import SwiftData

/// A student's claim on a seat. Availability counts are calculated from these records.
///
/// A check-in expires after `SeatHoldPolicy.duration` and can be extended up to
/// `SeatHoldPolicy.maximumDuration` in a single check-in.
/// Students can also give up the seat early.
/// When the student leaves the seat, `releasedAt` records when the check-in ended.
/// Only the student who made the check-in can release it.
///
/// A class is used because SwiftData persists this type and its dates can change over time.
/// The other persisted entities are classes for the same reason.
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
