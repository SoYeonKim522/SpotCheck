import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate {
    private let notificationActions = NotificationActionHandler()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = notificationActions
        return true
    }
}
