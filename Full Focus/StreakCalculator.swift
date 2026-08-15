import Foundation

struct DayRecord {
    let date: Date
    let totalMinutes: Int
    let photoFileName: String?
}

enum DayStatus {
    case completed(DayRecord)
    case missed
    case todayPending
}

struct DayInfo: Identifiable {
    let date: Date
    let status: DayStatus
    var id: Date { date }
}

struct StreakStats {
    let currentStreak: Int
    let bestStreak: Int
    let todayDone: Bool
}

/// Un giorno senza foto/sessione è "missed" per sempre. Con più attività
/// selezionate, un giorno conta come fatto solo se TUTTE quel giorno lo
/// sono — l'ordine tra loro non conta.
enum StreakCalculator {

    static func stats(completedDates: Set<Date>) -> StreakStats {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayDone = completedDates.contains(today)

        var current = 0
        var cursor = todayDone ? today : calendar.date(byAdding: .day, value: -1, to: today)!
        while completedDates.contains(cursor) {
            current += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }

        var best = 0
        var running = 0
        var previous: Date?
        for d in completedDates.sorted() {
            if let prev = previous, calendar.date(byAdding: .day, value: 1, to: prev) == d {
                running += 1
            } else {
                running = 1
            }
            best = max(best, running)
            previous = d
        }

        return StreakStats(currentStreak: current, bestStreak: max(best, current), todayDone: todayDone)
    }

    static func gridDays(completedDates: Set<Date>, dayRecords: [Date: DayRecord], firstDate: Date?) -> [DayInfo] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = firstDate ?? today

        var days: [DayInfo] = []
        var cursor = start
        while cursor <= today {
            let status: DayStatus
            if completedDates.contains(cursor), let record = dayRecords[cursor] {
                status = .completed(record)
            } else if cursor == today {
                status = .todayPending
            } else {
                status = .missed
            }
            days.append(DayInfo(date: cursor, status: status))
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return days
    }

    static func streakPositions(for days: [DayInfo]) -> [Date: Int] {
        var positions: [Date: Int] = [:]
        var running = 0
        for day in days {
            switch day.status {
            case .completed:
                running += 1
                positions[day.date] = running
            case .missed, .todayPending:
                running = 0
            }
        }
        return positions
    }
}
