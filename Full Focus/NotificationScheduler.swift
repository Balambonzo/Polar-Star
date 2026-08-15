import Foundation

final class NotificationScheduler {

    static let shared = NotificationScheduler()
    private init() {}

    static let notificationsEnabledKey = "notificationsEnabled"
    static let mainReminderHourKey = "mainReminderHour"
    static let mainReminderMinuteKey = "mainReminderMinute"

    func refreshSchedule(todayDone: Bool) {
        NotificationManager.shared.removeAllPending()

        let enabled = UserDefaults.standard.object(forKey: Self.notificationsEnabledKey) as? Bool ?? true
        guard enabled else { return }

        guard !todayDone else {
            scheduleInactivityReminder()
            return
        }

        let calendar = Calendar.current
        let now = Date()

        let hour = UserDefaults.standard.object(forKey: Self.mainReminderHourKey) as? Int ?? 19
        let minute = UserDefaults.standard.object(forKey: Self.mainReminderMinuteKey) as? Int ?? 0

        let tomorrow = calendar.startOfDay(
            for: calendar.date(byAdding: .day, value: 1, to: now)!
        )
        let expiration = calendar.date(byAdding: .second, value: -1, to: tomorrow)!

        let mainReminder = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now)!

        scheduleReminder(id: "main", date: mainReminder, message: MotivationalNotifications.randomWarning())
        scheduleReminder(id: "6h", date: expiration.addingTimeInterval(-21600), message: MotivationalNotifications.randomWarning())
        scheduleReminder(id: "2h", date: expiration.addingTimeInterval(-7200), message: MotivationalNotifications.randomWarning())
        scheduleReminder(id: "30m", date: expiration.addingTimeInterval(-1800), message: MotivationalNotifications.randomFinalWarning())

        scheduleInactivityReminder()
    }

    private func scheduleInactivityReminder() {
        scheduleReminder(
            id: "inactive",
            date: Date().addingTimeInterval(60 * 60 * 24 * 3),
            message: MotivationalNotifications.randomInactivity()
        )
    }

    private func scheduleReminder(id: String, date: Date, message: String) {
        guard date > Date() else { return }
        NotificationManager.shared.schedule(id: id, title: "Full Focus", body: message, date: date)
    }
}
