//TrainingSet.swift
import Foundation
import SwiftData

@Model
final class TrainingSet {
    var id: UUID = UUID()
    
    /// Numero di ripetizioni effettivamente eseguite.
    /// Per gli esercizi hold resta nil.
    var reps: Int? = nil
    
    /// Peso usato in kg.
    /// nil per esercizi a corpo libero o quando non applicabile.
    var weight: Double? = nil
    
    /// Rate of Perceived Exertion, 1...10.
    var rpe: Double = 8
    
    /// Durata effettiva per gli esercizi isometrici.
    var durationSeconds: Int? = nil
    
    /// 1-based index della serie nell'esercizio.
    var setNumber: Int = 1
    
    var completedAt: Date = Date()

    init(
        reps: Int?,
        weight: Double?,
        rpe: Double,
        durationSeconds: Int?,
        setNumber: Int
    ) {
        self.id = UUID()
        self.reps = reps
        self.weight = weight
        self.rpe = rpe
        self.durationSeconds = durationSeconds
        self.setNumber = setNumber
        self.completedAt = .now
    }
}
