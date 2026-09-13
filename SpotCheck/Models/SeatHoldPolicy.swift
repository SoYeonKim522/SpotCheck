//
//  SeatHoldPolicy.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 13/9/2026.
//

import Foundation

/// How long a seat stays held before it becomes available again
///
/// A check-in expires once this interval has passed, automatically freeing the seat.
/// Extending a check-in restarts the interval from the time it is extended.

enum SeatHoldPolicy {
    static let duration: TimeInterval = 60 * 60
}
