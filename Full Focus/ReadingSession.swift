import Foundation
import SwiftData

@Model
final class ReadingSession {
    var id: UUID = UUID()
    var date: Date = Date()
    var bookID: UUID = UUID()
    var minutesRead: Int = 0
    var pageReached: Int = 0
    var createdAt: Date = Date()

    init(date: Date, bookID: UUID, minutesRead: Int, pageReached: Int) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.bookID = bookID
        self.minutesRead = minutesRead
        self.pageReached = pageReached
        self.createdAt = .now
    }
}
