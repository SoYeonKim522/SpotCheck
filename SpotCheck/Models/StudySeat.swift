//
//  StudySeat.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 8/9/2026.
//

import Foundation
import SwiftData

/// A single seat that a student can check in to.
///
/// A seat is considered free when it has no active check-ins.
/// The app checks the seat's current check-ins whenever it needs to know
/// whether the seat is available, rather than storing its availability separately.
/// This means an expired check-in frees the seat automatically, without needing
/// a timer or a separate cleanup process.
@Model
final class StudySeat {
    var label: String
    var isByWindow: Bool
    var hasComputer: Bool
    var hasPowerOutlet: Bool
    var hasPartition: Bool
    var isSharedTable: Bool
    var zone: StudyZone?

    @Relationship(deleteRule: .cascade, inverse: \SeatCheckIn.seat)
    var checkIns: [SeatCheckIn] = []

    init(
        label: String,
        isByWindow: Bool = false,
        hasComputer: Bool = false,
        hasPowerOutlet: Bool = false,
        hasPartition: Bool = false,
        isSharedTable: Bool = false
    ) {
        self.label = label
        self.isByWindow = isByWindow
        self.hasComputer = hasComputer
        self.hasPowerOutlet = hasPowerOutlet
        self.hasPartition = hasPartition
        self.isSharedTable = isSharedTable
    }

    func activeCheckIn(at moment: Date) -> SeatCheckIn? {
        checkIns.first { $0.isActive(at: moment) }
    }
}
