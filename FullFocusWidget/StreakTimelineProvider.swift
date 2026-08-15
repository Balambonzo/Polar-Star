import WidgetKit

struct StreakEntry: TimelineEntry {
    let date: Date
    let currentStreak: Int
    let bestStreak: Int
    let todayDone: Bool
    let motivationalLine: String
}

struct StreakTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), currentStreak: 12, bestStreak: 30, todayDone: true,
                     motivationalLine: "Discipline is becoming your identity.")
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let entry = currentEntry()
        // Ricarica a mezzanotte: è il momento in cui "todayDone" torna false
        let midnight = Calendar.current.nextDate(
            after: Date(), matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }

    private func currentEntry() -> StreakEntry {
        guard let snapshot = WidgetSnapshotStore.load() else {
            return StreakEntry(date: Date(), currentStreak: 0, bestStreak: 0, todayDone: false,
                                motivationalLine: "Every master was once a beginner")
        }
        return StreakEntry(date: Date(), currentStreak: snapshot.currentStreak,
                            bestStreak: snapshot.bestStreak, todayDone: snapshot.todayDone,
                            motivationalLine: snapshot.motivationalLine)
    }
}
