import Foundation

/// Unifica i giorni completati e i dati del giorno (minuti totali, foto)
/// su qualunque combinazione di attività scelte — è la base condivisa da
/// streak, Collezione e widget, così nessuno di questi resta legato a
/// un'attività specifica.
enum ActivityAggregator {
    struct Result {
        let completedDates: Set<Date>
        let dayRecords: [Date: DayRecord]
        let firstDate: Date?
    }

    static func aggregate(
        selectedActivities: [String],
        studyEntries: [StudyEntry],
        trainingEntries: [TrainingEntry],
        readingSessions: [ReadingSession],
        customEntries: [CustomActivityEntry]
    ) -> Result {
        let calendar = Calendar.current

        var perActivityDates: [Set<Date>] = []
        var minutesByDate: [Date: Int] = [:]
        var photoByDate: [Date: String] = [:]
        var allDates: [Date] = []

        if selectedActivities.contains(ActivityKey.study.rawValue) {
            let dates = Set(studyEntries.map { calendar.startOfDay(for: $0.date) })
            perActivityDates.append(dates)
            for e in studyEntries {
                let d = calendar.startOfDay(for: e.date)
                minutesByDate[d, default: 0] += e.studyDurationMinutes
                photoByDate[d] = e.imageFileName
                allDates.append(d)
            }
        }
        if selectedActivities.contains(ActivityKey.training.rawValue) {
            let dates = Set(trainingEntries.map { calendar.startOfDay(for: $0.date) })
            perActivityDates.append(dates)
            for e in trainingEntries {
                let d = calendar.startOfDay(for: e.date)
                minutesByDate[d, default: 0] += e.durationMinutes
                allDates.append(d)
            }
        }
        if selectedActivities.contains(ActivityKey.reading.rawValue) {
            let dates = Set(readingSessions.map { calendar.startOfDay(for: $0.date) })
            perActivityDates.append(dates)
            for e in readingSessions {
                let d = calendar.startOfDay(for: e.date)
                minutesByDate[d, default: 0] += e.minutesRead
                allDates.append(d)
            }
        }
        if selectedActivities.contains(ActivityKey.custom.rawValue) {
            let dates = Set(customEntries.map { calendar.startOfDay(for: $0.date) })
            perActivityDates.append(dates)
            for e in customEntries {
                let d = calendar.startOfDay(for: e.date)
                minutesByDate[d, default: 0] += e.durationMinutes
                if photoByDate[d] == nil { photoByDate[d] = e.imageFileName }
                allDates.append(d)
            }
        }

        let completed: Set<Date>
        if perActivityDates.isEmpty {
            completed = []
        } else {
            completed = perActivityDates.dropFirst().reduce(perActivityDates[0]) { $0.intersection($1) }
        }

        var records: [Date: DayRecord] = [:]
        for d in completed {
            records[d] = DayRecord(date: d, totalMinutes: minutesByDate[d] ?? 0, photoFileName: photoByDate[d])
        }

        return Result(completedDates: completed, dayRecords: records, firstDate: allDates.min())
    }
}
