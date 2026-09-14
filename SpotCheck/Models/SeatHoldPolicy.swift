//
//  SeatHoldPolicy.swift
//  SpotCheck
//
//  Created by MACBOOK_PRO on 13/9/2026.
//

import Foundation

/// Defines how long a seat can be held and how long one student can keep it.
///
/// A check-in expires after `duration` and the seat becomes available again.
/// Each extension adds another `duration`, but a single check-in cannot last longer
/// than `maximumDuration` from the time it was made.
enum SeatHoldPolicy {
    static let duration: TimeInterval = 60 * 60
    static let maximumDuration: TimeInterval = 3 * 60 * 60

    static func latestExpiry(for checkedInAt: Date) -> Date {
        checkedInAt.addingTimeInterval(maximumDuration)
    }

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
