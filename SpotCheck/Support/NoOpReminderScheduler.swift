import Foundation

/// A reminder scheduler that does nothing.
///
/// The screens use it until the notification extension branch adds the real scheduler.
struct NoOpReminderScheduler: ExpiryReminderScheduling {
    func scheduleReminder(for hold: SeatHold) {}

    func cancelReminder(forCheckInID id: UUID) {}
}
