import Foundation
@testable import SpotCheck

final class MockReminderScheduler: ExpiryReminderScheduling {
    private(set) var scheduledHolds: [SeatHold] = []
    private(set) var cancelledCheckInIDs: [UUID] = []

    func scheduleReminder(for hold: SeatHold) {
        scheduledHolds.append(hold)
    }

    func cancelReminder(forCheckInID id: UUID) {
        cancelledCheckInIDs.append(id)
    }
}
