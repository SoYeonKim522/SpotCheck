import Foundation

/// What the widget shows, written by the app and read from the App Group container.
///
/// The widget never calls Supabase. It has no session and may have no network, and a widget
/// stuck on "No data" is worse than a widget showing an old number honestly. So the app writes
/// this down after every read, and the widget renders it with its own age attached.
///
/// `readAt` records when the level counts were fetched. Counts can become outdated over time, so the widget uses `readAt`  to decide when they are stale.
///
/// A hold is governed by its `expiresAt`, which remains valid even when the app is not running. The widget can therefore count down to the expiry time itself.
struct AvailabilitySnapshot: Codable, Hashable {
    let buildingName: String
    let levels: [LevelCount]
    let hold: HeldSeat?
    let readAt: Date

    /// How long a level's seat count is considered fresh enough to show as current.
    static let freshnessWindow: TimeInterval = 15 * 60

    func isRecent(at moment: Date) -> Bool {
        moment.timeIntervalSince(readAt) < Self.freshnessWindow
    }

    /// The level worth walking to, for the sizes that only fit one.
    var emptiestLevel: LevelCount? {
        levels.max { $0.free < $1.free }
    }

    struct LevelCount: Codable, Hashable, Identifiable {
        let id: UUID
        let number: Int
        let free: Int
        let total: Int

        var fullness: LevelFullness {
            LevelFullness(free: free, total: total)
        }
    }

    struct HeldSeat: Codable, Hashable {
        let seatLabel: String
        let zoneName: String
        let levelNumber: Int
        let expiresAt: Date
    }
}
