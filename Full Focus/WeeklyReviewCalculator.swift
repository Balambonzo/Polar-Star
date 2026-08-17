import Foundation

enum WeeklyTrend {
    case up, down, steady
}

enum DayReviewState {
    case perfect
    case incomplete
    case todayPending
    case future
}

struct WeeklyReviewComparison {
    let perfectDays: Int
    let totalMinutes: Int
    let activitiesCompleted: Int
}

struct WeeklyReviewData {
    let weekStart: Date
    let weekEnd: Date
    let daysElapsed: Int

    let perfectDays: Int
    let activitiesCompleted: Int
    let totalMinutes: Int
    let studyMinutes: Int
    let trainingSessions: Int
    let readingMinutes: Int

    let currentStreak: Int
    let bestStreak: Int

    let previousWeek: WeeklyReviewComparison
    let trend: WeeklyTrend

    let dayStates: [DayReviewState] // 7, lunedì → domenica
    let suggestion: String
}

/// Tutta la logica statistica della Weekly Review vive qui — la UI si
/// limita a leggere `WeeklyReviewData`, mai a calcolare nulla da sola.
enum WeeklyReviewCalculator {
    
    static func compute(
        selectedActivities: [String],
        customActivityName: String?,
        studyEntries: [StudyEntry],
        trainingEntries: [TrainingEntry],
        readingSessions: [ReadingSession],
        customEntries: [CustomActivityEntry]
    ) -> WeeklyReviewData {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today) // 1 = domenica
        let daysSinceMonday = (weekday + 5) % 7
        let weekStart = calendar.date(byAdding: .day, value: -daysSinceMonday, to: today)!
        let daysElapsed = daysSinceMonday + 1
        
        let previousWeekStart = calendar.date(byAdding: .day, value: -7, to: weekStart)!
        let previousWeekEnd = calendar.date(byAdding: .day, value: daysElapsed - 1, to: previousWeekStart)!
        
        let current = metrics(
            from: weekStart, through: today, selectedActivities: selectedActivities,
            studyEntries: studyEntries, trainingEntries: trainingEntries,
            readingSessions: readingSessions, customEntries: customEntries
        )
        let previous = metrics(
            from: previousWeekStart, through: previousWeekEnd, selectedActivities: selectedActivities,
            studyEntries: studyEntries, trainingEntries: trainingEntries,
            readingSessions: readingSessions, customEntries: customEntries
        )
        
        let fullAggregation = ActivityAggregator.aggregate(
            selectedActivities: selectedActivities,
            studyEntries: studyEntries, trainingEntries: trainingEntries,
            readingSessions: readingSessions, customEntries: customEntries
        )
        let streakStats = StreakCalculator.stats(completedDates: fullAggregation.completedDates)
        
        let trend: WeeklyTrend
        if previous.totalMinutes == 0 && current.totalMinutes == 0 {
            trend = .steady
        } else if previous.totalMinutes == 0 {
            trend = .up
        } else {
            let change = Double(current.totalMinutes - previous.totalMinutes) / Double(previous.totalMinutes)
            trend = change > 0.1 ? .up : (change < -0.1 ? .down : .steady)
        }
        
        var dayStates: [DayReviewState] = []
        for offset in 0..<7 {
            let day = calendar.date(byAdding: .day, value: offset, to: weekStart)!
            if day > today {
                dayStates.append(.future)
            } else if fullAggregation.completedDates.contains(day) {
                dayStates.append(.perfect)
            } else if day == today {
                dayStates.append(.todayPending)
            } else {
                dayStates.append(.incomplete)
            }
        }
        
        let suggestion = makeSuggestion(
            selectedActivities: selectedActivities,
            customActivityName: customActivityName,
            current: current,
            daysElapsed: daysElapsed,
            dayStates: dayStates
        )
        
        return WeeklyReviewData(
            weekStart: weekStart, weekEnd: today, daysElapsed: daysElapsed,
            perfectDays: current.perfectDays,
            activitiesCompleted: current.activitiesCompleted,
            totalMinutes: current.totalMinutes,
            studyMinutes: current.studyMinutes,
            trainingSessions: current.trainingSessionsCount,
            readingMinutes: current.readingMinutes,
            currentStreak: streakStats.currentStreak,
            bestStreak: streakStats.bestStreak,
            previousWeek: WeeklyReviewComparison(
                perfectDays: previous.perfectDays,
                totalMinutes: previous.totalMinutes,
                activitiesCompleted: previous.activitiesCompleted
            ),
            trend: trend,
            dayStates: dayStates,
            suggestion: suggestion
        )
    }
    
    // MARK: - Metriche su una finestra di date
    
    private struct WindowMetrics {
        var perfectDays = 0
        var activitiesCompleted = 0
        var totalMinutes = 0
        var studyMinutes = 0
        var trainingSessionsCount = 0
        var readingMinutes = 0
        var activityCounts: [String: Int] = [:]
    }
    
    private static func metrics(
        from start: Date, through end: Date,
        selectedActivities: [String],
        studyEntries: [StudyEntry], trainingEntries: [TrainingEntry],
        readingSessions: [ReadingSession], customEntries: [CustomActivityEntry]
    ) -> WindowMetrics {
        let calendar = Calendar.current
        func inRange(_ date: Date) -> Bool {
            let d = calendar.startOfDay(for: date)
            return d >= start && d <= end
        }
        
        let studyInWeek = studyEntries.filter { inRange($0.date) }
        let trainingInWeek = trainingEntries.filter { inRange($0.date) }
        let readingInWeek = readingSessions.filter { inRange($0.date) }
        let customInWeek = customEntries.filter { inRange($0.date) }
        
        var m = WindowMetrics()
        m.studyMinutes = studyInWeek.reduce(0) { $0 + $1.studyDurationMinutes }
        m.trainingSessionsCount = trainingInWeek.count
        m.readingMinutes = readingInWeek.reduce(0) { $0 + $1.minutesRead }
        let trainingMinutes = trainingInWeek.reduce(0) { $0 + $1.durationMinutes }
        let customMinutes = customInWeek.reduce(0) { $0 + $1.durationMinutes }
        m.totalMinutes = m.studyMinutes + trainingMinutes + m.readingMinutes + customMinutes
        m.activitiesCompleted = studyInWeek.count + trainingInWeek.count + readingInWeek.count + customInWeek.count
        
        m.activityCounts = [
            ActivityKey.study.rawValue: studyInWeek.count,
            ActivityKey.training.rawValue: trainingInWeek.count,
            ActivityKey.reading.rawValue: readingInWeek.count,
            ActivityKey.custom.rawValue: customInWeek.count
        ]
        
        let aggregation = ActivityAggregator.aggregate(
            selectedActivities: selectedActivities,
            studyEntries: studyInWeek, trainingEntries: trainingInWeek,
            readingSessions: readingInWeek, customEntries: customInWeek
        )
        m.perfectDays = aggregation.completedDates.filter { $0 >= start && $0 <= end }.count
        
        return m
    }
    
    

    
    // MARK: - Suggerimento, derivato solo da numeri reali
    
    private static func makeSuggestion(
        selectedActivities: [String],
        customActivityName: String?,
        current: WindowMetrics,
        daysElapsed: Int,
        dayStates: [DayReviewState]
    ) -> String {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "en_US")
        let weekdaySymbols = calendar.standaloneWeekdaySymbols // Sunday-based
        func label(for key: String) -> String {
            switch key {
            case ActivityKey.study.rawValue: return "Study"
            case ActivityKey.training.rawValue: return "Training"
            case ActivityKey.reading.rawValue: return "Reading"
            default: return customActivityName ?? "the custom activity"
            }
        }
        
        // 1) If there are at least 2 activities, check if one is clearly falling behind.
        if selectedActivities.count > 1 {
            let relevant = selectedActivities.compactMap { key in
                current.activityCounts[key].map { (key, $0) }
            }
            if let minEntry = relevant.min(by: { $0.1 < $1.1 }),
               let maxEntry = relevant.max(by: { $0.1 < $1.1 }),
               maxEntry.1 > 0, minEntry.1 < maxEntry.1, minEntry.1 <= daysElapsed / 2 {
                return "This week \(label(for: minEntry.0)) has fallen a bit behind the rest — it might help to move it earlier in the day."
            }
        }
        
        // 2) If the week (so far) is full, acknowledge it without forcing another suggestion.
        let pastDays = dayStates.prefix(daysElapsed)
        if pastDays.allSatisfy({ $0 == .perfect || $0 == .todayPending }) {
            return "Full week so far — nothing to suggest, keep it up."
        }
        
        // 3) Otherwise, flag the incomplete days in a neutral way.
        let incompleteWeekdays: [String] = dayStates.enumerated().compactMap { index, state in
            guard state == .incomplete else { return nil }
            let weekdayIndex = (index + 1) % 7 // 0=Monday → Sunday-based index
            return weekdaySymbols[weekdayIndex].capitalized
        }
        if !incompleteWeekdays.isEmpty {
            let list = incompleteWeekdays.joined(separator: ", ")
            return "\(list): days where you didn't complete all activities — it happens, try to notice if there's a recurring reason."
        }
        
        return "Keep showing up every day: that's what matters most."
    }
}
