//
//  StudyZone.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 8/9/2026.
//

import Foundation
import SwiftData

/// A named area within a level, such as a reading room or open seating.
///
/// `noiseLevel` uses the university's official designation. If the university
/// has not provided one, it is `nil`. It is not based on personal opinions.
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
