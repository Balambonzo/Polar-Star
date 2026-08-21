import Foundation
import SwiftData

@Model
final class StudyEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var imageFileName: String = ""
    var createdAt: Date = Date()
    var studyDurationMinutes: Int = 0
    var theoryMinutes: Int = 0       // ← nuovo
    var exerciseMinutes: Int = 0     // ← nuovo

    init(date: Date, imageFileName: String, studyDurationMinutes: Int = 0, theoryMinutes: Int = 0, exerciseMinutes: Int = 0) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.imageFileName = imageFileName
        self.createdAt = .now
        self.studyDurationMinutes = studyDurationMinutes
        self.theoryMinutes = theoryMinutes
        self.exerciseMinutes = exerciseMinutes
    }
}
