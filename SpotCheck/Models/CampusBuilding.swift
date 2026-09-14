//
//  CampusBuilding.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 8/9/2026.
//

import Foundation
import SwiftData

/// A building on the UTS campus that students can study in.
///
/// Names are unique because a name is also what students see and choose by ("Building 2").
@Model
final class CampusBuilding {
    @Attribute(.unique) var name: String
    var address: String
    var displayOrder: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \StudyLevel.building)
    var levels: [StudyLevel] = []

    init(name: String, address: String) {
        self.name = name
        self.address = address
    }
}
