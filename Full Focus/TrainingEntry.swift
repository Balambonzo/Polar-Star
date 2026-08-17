//TrainingEntry.swift
import Foundation
import SwiftData

@Model
final class TrainingEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var muscleGroups: [String] = []
    var level: String = ""
    
    /// Durata reale dell'intero workout, dall'avvio alla conclusione.
    var durationMinutes: Int = 0
    
    /// Il workout viene creato quando parte la sessione, ma conta
    /// per streak/statistiche solamente quando è completato.
    var isCompleted: Bool = false
    
    var startedAt: Date = Date()
    var completedAt: Date? = nil
    var createdAt: Date = Date()
    
    @Relationship(deleteRule: .cascade)
    var exercises: [TrainingExercise] = []

    init(
        date: Date,
        muscleGroups: [String],
        level: TrainingLevel,
        startedAt: Date = .now
    ) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.muscleGroups = muscleGroups
        self.level = level.rawValue
        self.durationMinutes = 0
        self.isCompleted = false
        self.startedAt = startedAt
        self.completedAt = nil
        self.createdAt = .now
    }
}
