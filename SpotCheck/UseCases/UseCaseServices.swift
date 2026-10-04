import Foundation

/// Reloads the widget after a change that moves a seat count.
///
/// The use cases depend on this protocol, so a test can check that a reload was asked for
/// without touching WidgetKit. Production calls `WidgetCenter.shared.reloadAllTimelines()`.
protocol WidgetRefreshing {
    func reloadAll()
}

/// Schedules and cancels the reminder that fires before a hold ends.
///
/// The reminder takes a `SeatHold` because its notification shows the seat, the level and the
/// time left. The use case reads the hold back after a check-in so this has the seat's location,
/// which the check-in on its own does not carry.
protocol ExpiryReminderScheduling {
    func scheduleReminder(for hold: SeatHold)
    func cancelReminder(forCheckInID id: UUID)
}
