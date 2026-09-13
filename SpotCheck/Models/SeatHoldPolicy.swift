//
//  SeatHoldPolicy.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 13/9/2026.
//

import Foundation

/// How long a seat stays held, and how long it can be held for in one sitting.

/// A check-in expires once `duration` has passed, automatically freeing the seat.
/// Extending a hold adds another `duration`,
/// but a single check-in can never run longer than `maximumDuration`from the moment it was made.

enum SeatHoldPolicy {
    static let duration: TimeInterval = 60 * 60
    static let maximumDuration: TimeInterval = 3 * 60 * 60

    static var durationText: String {
        text(for: duration)
    }

    static var maximumDurationText: String {
        text(for: maximumDuration)
    }

    private static func text(for interval: TimeInterval) -> String {
        Duration.seconds(interval).formatted(.units(allowed: [.hours, .minutes], width: .wide))
    }
}
