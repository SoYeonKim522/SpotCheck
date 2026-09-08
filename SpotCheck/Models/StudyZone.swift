//
//  StudyZone.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 8/9/2026.
//

import Foundation
import SwiftData

@Model
final class StudyZone {
    var name: String
    var noiseLevel: NoiseLevel?
    var level: StudyLevel?

    @Relationship(deleteRule: .cascade, inverse: \StudySeat.zone)
    var seats: [StudySeat] = []

    var capacity: Int {
        seats.count
    }

    init(name: String, noiseLevel: NoiseLevel? = nil) {
        self.name = name
        self.noiseLevel = noiseLevel
    }
}
