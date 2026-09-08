//
//  CampusBuilding.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 8/9/2026.
//

import Foundation
import SwiftData

@Model
final class CampusBuilding {
    @Attribute(.unique) var name: String
    var address: String

    @Relationship(deleteRule: .cascade, inverse: \StudyLevel.building)
    var levels: [StudyLevel] = []

    init(name: String, address: String) {
        self.name = name
        self.address = address
    }
}
