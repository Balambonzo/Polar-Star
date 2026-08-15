import Foundation
import SwiftData

@Model
final class StudyEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var imageFileName: String = ""
    var createdAt: Date = Date()
    var studyDurationMinutes: Int = 0

    init(date: Date, imageFileName: String, studyDurationMinutes: Int = 0) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.imageFileName = imageFileName
        self.createdAt = .now
        self.studyDurationMinutes = studyDurationMinutes
    }
}
