//
//  StudyLevel.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 8/9/2026.
//

import Foundation
import SwiftData

/// One floor of a building, which students can choose from.
///
/// Floors can differ in noise, zone type, and seat features, so availability is shown
/// separately for each floor rather than for the whole building.
/// `capacity` is calculated from the zones when needed, so it always stays up to date.
@Model
final class StudyLevel {
    var number: Int
    var building: CampusBuilding?

    @Relationship(deleteRule: .cascade, inverse: \StudyZone.level)
    var zones: [StudyZone] = []

    var capacity: Int {
        zones.reduce(0) { $0 + $1.capacity }
    }

    init(number: Int) {
        self.number = number
    }
}
