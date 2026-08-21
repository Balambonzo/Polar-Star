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

        scheduleWeeklyReviewReminder()

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

    /// La prossima domenica alle 8:00 — ricalcolata ogni volta che
    /// refreshSchedule() gira (come le altre, viene ri-schedulata invece di
    /// restare "repeats: true" a tempo indeterminato, per restare coerente
    /// con come funziona già il resto di questo scheduler).
    private func scheduleWeeklyReviewReminder() {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now) // 1 = domenica
        let daysUntilSunday = (8 - weekday) % 7 // 0 se oggi è già domenica

        guard let candidateDay = calendar.date(byAdding: .day, value: daysUntilSunday, to: calendar.startOfDay(for: now)),
              var fireDate = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: candidateDay) else { return }

        if fireDate <= now {
            fireDate = calendar.date(byAdding: .day, value: 7, to: fireDate) ?? fireDate
        }

        scheduleReminder(id: "weeklyReview", date: fireDate, message: Self.weeklyReviewMessages.randomElement() ?? Self.weeklyReviewMessages[0])
    }

    private static let weeklyReviewMessages = [
        "Your week is ready to be seen. Take two minutes to look at what you built.",
        "Sunday check-in: see how far this week took you.",
        "Before the week resets, take a look at what you actually did.",
        "Your Weekly Review is ready — a quick look, then move on with your day.",
        "Numbers don't lie: come see what this week says about you."
    ]

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
