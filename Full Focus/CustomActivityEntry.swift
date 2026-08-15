import Foundation
import SwiftData

@Model
final class CustomActivityEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var imageFileName: String = ""
    var durationMinutes: Int = 0
    var createdAt: Date = Date()

    init(date: Date, imageFileName: String, durationMinutes: Int) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.imageFileName = imageFileName
        self.durationMinutes = durationMinutes
        self.createdAt = .now
    }
}
