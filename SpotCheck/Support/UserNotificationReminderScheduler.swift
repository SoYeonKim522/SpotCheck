import Foundation
import UserNotifications

struct UserNotificationReminderScheduler: ExpiryReminderScheduling {
    private let center = UNUserNotificationCenter.current()

    init() {
        center.setNotificationCategories([
            UNNotificationCategory(
                identifier: ReminderNotification.categoryIdentifier,
                actions: [
                    UNNotificationAction(
                        identifier: ReminderNotification.Action.extendHold,
                        title: "Hold for another hour"
                    ),
                    UNNotificationAction(
                        identifier: ReminderNotification.Action.releaseSeat,
                        title: "Release",
                        options: .destructive
                    )
                ],
                intentIdentifiers: []
            )
        ])
    }

    func scheduleReminder(for hold: SeatHold) {
        let fireDate = hold.checkIn.expiresAt.addingTimeInterval(-SeatHoldPolicy.reminderLead)
        let delay = fireDate.timeIntervalSinceNow
        guard delay > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Your seat reservation ends soon"
        content.body = "Seat \(hold.seatLabel) on Level \(hold.levelNumber) is held until \(hold.checkIn.expiresAt.formatted(date: .omitted, time: .shortened))."
        content.sound = .default
        content.categoryIdentifier = ReminderNotification.categoryIdentifier
        content.userInfo = [
            ReminderNotification.UserInfoKey.checkInID: hold.checkIn.id.uuidString,
            ReminderNotification.UserInfoKey.seatLabel: hold.seatLabel,
            ReminderNotification.UserInfoKey.zoneName: hold.zoneName,
            ReminderNotification.UserInfoKey.levelNumber: hold.levelNumber,
            ReminderNotification.UserInfoKey.buildingName: hold.buildingName,
            ReminderNotification.UserInfoKey.expiresAt: hold.checkIn.expiresAt.timeIntervalSince1970
        ]

        let request = UNNotificationRequest(
            identifier: hold.checkIn.id.uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        )

        Task {
            guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return }
            try? await center.add(request)
        }
    }

    func cancelReminder(forCheckInID id: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [id.uuidString])
        center.removeDeliveredNotifications(withIdentifiers: [id.uuidString])
    }
}
