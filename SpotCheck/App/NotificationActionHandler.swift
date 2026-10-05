import Foundation
import UserNotifications

final class NotificationActionHandler: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let action = response.actionIdentifier
        guard action == ReminderNotification.Action.extendHold || action == ReminderNotification.Action.releaseSeat,
              let checkInID = (response.notification.request.content.userInfo[ReminderNotification.UserInfoKey.checkInID] as? String)
                .flatMap(UUID.init)
        else { return }

        let repository = SupabaseStudySpaceRepository()
        let reminders = UserNotificationReminderScheduler()
        let widget = WidgetCenterRefresher()
        let snapshot = AvailabilitySnapshotStore()

        guard let occupant = await SupabaseAuthenticationRepository().restoreOccupant() else { return }

        let now = Date.now
        do {
            guard let hold = try await repository.activeHold(for: occupant, at: now), hold.id == checkInID else { return }

            if action == ReminderNotification.Action.extendHold {
                _ = try await ExtendHoldUseCase(repository: repository, reminders: reminders, widget: widget, snapshot: snapshot)
                    .execute(hold: hold, occupant: occupant, now: now)
            } else {
                try await ReleaseSeatUseCase(repository: repository, reminders: reminders, widget: widget, snapshot: snapshot)
                    .execute(checkIn: hold.checkIn, occupant: occupant, now: now)
            }
        } catch {
            await tellThePersonAbout(error, using: center)
        }
    }

    private func tellThePersonAbout(_ error: any Error, using center: UNUserNotificationCenter) async {
        let content = UNMutableNotificationContent()
        switch error {
        case let error as ExtendHoldError:
            content.title = error.errorDescription ?? ""
            content.body = error.recoverySuggestion ?? ""
        case let error as ReleaseSeatError:
            content.title = error.errorDescription ?? ""
            content.body = error.recoverySuggestion ?? ""
        default:
            content.title = "Couldn't reach SpotCheck"
            content.body = "Open the app to check your seat."
        }
        try? await center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }
}
