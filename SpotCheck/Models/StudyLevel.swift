//
//  StudyLevel.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 8/9/2026.
//

import Foundation
import SwiftData

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
