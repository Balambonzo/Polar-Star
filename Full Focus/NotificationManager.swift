import Foundation
import UserNotifications

final class NotificationManager {

    static let shared = NotificationManager()

    private init() {}

    func requestAuthorization() {

        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { _, _ in }

    }

    func removeAllPending() {

        UNUserNotificationCenter.current()
            .removeAllPendingNotificationRequests()

    }

    func schedule(
        id: String,
        title: String,
        body: String,
        date: Date
    ) {

        let content = UNMutableNotificationContent()

        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year,.month,.day,.hour,.minute],
            from: date
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current()
            .add(request)

    }

}
