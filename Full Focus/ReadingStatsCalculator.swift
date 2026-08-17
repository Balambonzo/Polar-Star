import Foundation

struct ReadingStats {
    let currentStreak: Int
    let bestStreak: Int
    let totalMinutes: Int
    let booksCompleted: Int
    let sessionsCount: Int
}

/// Calcola tutte le statistiche di lettura a partire da Book e
/// ReadingSession esistenti — nessun dato nuovo da salvare.
enum ReadingStatsCalculator {

    static func stats(sessions: [ReadingSession], books: [Book]) -> ReadingStats {
        let calendar = Calendar.current
        let dates = Set(sessions.map { calendar.startOfDay(for: $0.date) })
        let base = StreakCalculator.stats(completedDates: dates)
        let totalMinutes = sessions.reduce(0) { $0 + $1.minutesRead }
        let completed = books.filter { $0.isCompleted }.count
        return ReadingStats(
            currentStreak: base.currentStreak,
            bestStreak: base.bestStreak,
            totalMinutes: totalMinutes,
            booksCompleted: completed,
            sessionsCount: sessions.count
        )
    }

    /// Pagine lette in questa sessione: differenza rispetto all'ultima
    /// sessione precedente per lo stesso libro (0 se è la prima).
    static func pagesRead(in session: ReadingSession, allSessions: [ReadingSession]) -> Int {
        let previous = allSessions
            .filter { $0.bookID == session.bookID && $0.date < session.date }
            .sorted { $0.date > $1.date }
            .first
        let previousPage = previous?.pageReached ?? 0
        return max(0, session.pageReached - previousPage)
    }

    static func monthlyPagesTotal(sessions: [ReadingSession]) -> Int {
        let calendar = Calendar.current
        let now = Date()
        return sessions
            .filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + pagesRead(in: $1, allSessions: sessions) }
    }

    /// Pagine giorno per giorno negli ultimi `days` giorni (finestra
    /// scorrevole, non legata al mese di calendario — utile per il
    /// grafico, indipendentemente da che giorno del mese sei).
    static func recentDailyPages(sessions: [ReadingSession], days: Int = 14) -> [(date: Date, pages: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var result: [(Date, Int)] = []
        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            if let session = sessions.first(where: { calendar.isDate($0.date, inSameDayAs: day) }) {
                result.append((day, pagesRead(in: session, allSessions: sessions)))
            } else {
                result.append((day, 0))
            }
        }
        return result
    }

    /// Ritmo medio di lettura di un libro, in pagine al giorno da quando
    /// l'hai iniziato.
    static func pace(for book: Book) -> Double? {
        guard book.currentPage > 0 else { return nil }
        let days = max(1, Calendar.current.dateComponents([.day], from: book.startedAt, to: Date()).day ?? 1)
        return Double(book.currentPage) / Double(days)
    }
}
