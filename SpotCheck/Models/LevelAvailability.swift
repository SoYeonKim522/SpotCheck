//
//  LevelAvailability.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 9/9/2026.
//

import Foundation

/// The number of free seats on one level at a single moment.
///
/// The count is calculated from the level's check-ins rather than stored.
/// `free` does not include seats held by a check-in that has not expired yet.
/// `lastUpdatedAt` records when the numbers were read. It is kept in the same type
/// so that a count is always shown with the time it was read.
///
/// A struct is used because these values are calculated on every read and are not persisted.
/// It also keeps a reference to its `StudyLevel` so a screen can move from a row to that
/// level's seats.
struct LevelAvailability {
    let level: StudyLevel
    let free: Int
    let total: Int
    let lastUpdatedAt: Date

    /// How full this level is. See `LevelFullness`.
    var fullness: LevelFullness {
        LevelFullness(free: free, total: total)
    }
}
