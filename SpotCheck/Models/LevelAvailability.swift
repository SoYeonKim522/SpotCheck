//
//  LevelAvailability.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 9/9/2026.
//

import Foundation

/// Free seats on one level at a single moment, derived from its check-ins rather than stored.
///
/// `free` excludes seats held by an unexpired check-in; an expired one no longer holds its seat.
/// `lastUpdatedAt` is the level's most recent check-in or release, `nil` if there is none.
/// A free-seat count is never shown without it.
struct LevelAvailability {
    let levelNumber: Int
    let free: Int
    let total: Int
    let lastUpdatedAt: Date?
}
