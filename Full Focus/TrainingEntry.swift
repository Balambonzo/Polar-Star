import Foundation
import SwiftData

@Model
final class TrainingEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var muscleGroups: [String] = []
    var level: String = ""
    var durationMinutes: Int = 0
    var createdAt: Date = Date()

    init(date: Date, muscleGroups: [String], level: TrainingLevel, durationMinutes: Int) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.muscleGroups = muscleGroups
        self.level = level.rawValue
        self.durationMinutes = durationMinutes
        self.createdAt = .now
    }
}
