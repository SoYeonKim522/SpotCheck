//
//  LevelFullness.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 14/9/2026.
//

import Foundation

/// Describes how full a level is to help students decide where to go.
///
/// `plenty` means a student can expect to find a seat without looking hard.
/// `fillingUp` means seats are still free, but a student may need to walk around
/// to find one. `nearlyFull` means there are very few seats left, so the level
/// may not be worth going to. A level with no seats is also `nearlyFull`.
///
/// The two thresholds are based on what is useful for students when choosing
/// a level. They are not rules the app enforces.
enum LevelFullness {
    case plenty
    case fillingUp
    case nearlyFull

    init(free: Int, total: Int) {
        let freeFraction = total > 0 ? Double(free) / Double(total) : 0
        if freeFraction >= Self.plentyThreshold {
            self = .plenty
        } else if freeFraction < Self.nearlyFullThreshold {
            self = .nearlyFull
        } else {
            self = .fillingUp
        }
    }

    private static let plentyThreshold = 0.5
    private static let nearlyFullThreshold = 0.2
}
