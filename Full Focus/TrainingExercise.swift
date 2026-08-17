//TrainingExercise.swift
import Foundation
import SwiftData

@Model
final class TrainingExercise {
    var id: UUID = UUID()
    
    var name: String = ""
    var muscleGroup: String = ""
    var cue: String = ""
    var mode: String = ExerciseMode.reps.rawValue
    
    /// Numero di serie previste dal piano.
    var targetSets: Int = 1
    
    /// Per gli esercizi a ripetizioni.
    var targetReps: Int? = nil
    
    /// Per gli esercizi isometrici.
    var targetHoldSeconds: Int? = nil
    
    /// Recupero dopo ogni serie.
    var restSeconds: Int = 60
    
    /// Ordine dell'esercizio nel workout.
    var order: Int = 0
    
    @Relationship(deleteRule: .cascade)
    var sets: [TrainingSet] = []

    init(
        name: String,
        muscleGroup: String,
        cue: String,
        mode: ExerciseMode,
        targetSets: Int,
        targetReps: Int?,
        targetHoldSeconds: Int?,
        restSeconds: Int,
        order: Int
    ) {
        self.id = UUID()
        self.name = name
        self.muscleGroup = muscleGroup
        self.cue = cue
        self.mode = mode.rawValue
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetHoldSeconds = targetHoldSeconds
        self.restSeconds = restSeconds
        self.order = order
    }

    var exerciseMode: ExerciseMode {
        ExerciseMode(rawValue: mode) ?? .reps
    }
}
