//WorkoutPlan.swift
import Foundation

enum TrainingLevel: String, CaseIterable, Codable {
    case beginner
    case intermediate
    case advanced

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }

    /// Rimane disponibile per compatibilità con eventuale codice
    /// precedente, ma NON viene più usato per determinare la durata
    /// del workout.
    var minimumSessionMinutes: Int {
        switch self {
        case .beginner: return 15
        case .intermediate: return 20
        case .advanced: return 25
        }
    }

    var startingChainOffset: Int {
        switch self {
        case .beginner: return 0
        case .intermediate: return 1
        case .advanced: return 2
        }
    }
}

enum ExerciseMode: String, Codable {
    case reps
    case hold
}

struct ExerciseDefinition {
    let name: String
    let muscleGroup: String
    let cue: String
    let mode: ExerciseMode
    
    let targetSets: Int
    let targetReps: Int?
    let targetHoldSeconds: Int?
    
    /// Recupero tra le serie.
    let restSeconds: Int
}

enum WorkoutPlan {

    static let allMuscleGroups = [
        "Chest", "Shoulders", "Arms", "Back", "Legs", "Core"
    ]

    static let chains: [String: [ExerciseDefinition]] = [

        "Chest": [
            ExerciseDefinition(
                name: "Wall Push-Ups",
                muscleGroup: "Chest",
                cue: "Keep your body straight, stabilize your shoulder blades, and lower yourself with control.",
                mode: .reps,
                targetSets: 4,
                targetReps: 15,
                targetHoldSeconds: nil,
                restSeconds: 60
            ),
            ExerciseDefinition(
                name: "Incline Push-Ups",
                muscleGroup: "Chest",
                cue: "Place your hands on an elevated surface, keeping your elbows at 45°.",
                mode: .reps,
                targetSets: 4,
                targetReps: 12,
                targetHoldSeconds: nil,
                restSeconds: 60
            ),
            ExerciseDefinition(
                name: "Knee Push-Ups",
                muscleGroup: "Chest",
                cue: "Keep a straight line from your knees to your head.",
                mode: .reps,
                targetSets: 4,
                targetReps: 12,
                targetHoldSeconds: nil,
                restSeconds: 60
            ),
            ExerciseDefinition(
                name: "Full Push-Ups",
                muscleGroup: "Chest",
                cue: "Lower your chest toward the floor while keeping your body rigid like a plank.",
                mode: .reps,
                targetSets: 4,
                targetReps: 10,
                targetHoldSeconds: nil,
                restSeconds: 75
            ),
            ExerciseDefinition(
                name: "Diamond Push-Ups",
                muscleGroup: "Chest",
                cue: "Place your hands in a diamond shape underneath your sternum.",
                mode: .reps,
                targetSets: 4,
                targetReps: 8,
                targetHoldSeconds: nil,
                restSeconds: 75
            ),
            ExerciseDefinition(
                name: "Decline Push-Ups",
                muscleGroup: "Chest",
                cue: "Place your feet on an elevated surface to increase the load on your upper chest.",
                mode: .reps,
                targetSets: 4,
                targetReps: 10,
                targetHoldSeconds: nil,
                restSeconds: 75
            )
        ],

        "Shoulders": [
            ExerciseDefinition(
                name: "Pike Push-Ups",
                muscleGroup: "Shoulders",
                cue: "Keep your hips high in a V position and lower your head toward the floor.",
                mode: .reps,
                targetSets: 4,
                targetReps: 15,
                targetHoldSeconds: nil,
                restSeconds: 60
            ),
            ExerciseDefinition(
                name: "Feet-Elevated Pike Push-Ups",
                muscleGroup: "Shoulders",
                cue: "A more vertical position places more load on your shoulders.",
                mode: .reps,
                targetSets: 4,
                targetReps: 12,
                targetHoldSeconds: nil,
                restSeconds: 75
            ),
            ExerciseDefinition(
                name: "Wall Handstand Hold",
                muscleGroup: "Shoulders",
                cue: "Keep your body aligned with your back against the wall.",
                mode: .hold,
                targetSets: 4,
                targetReps: nil,
                targetHoldSeconds: 30,
                restSeconds: 60
            ),
            ExerciseDefinition(
                name: "Wall HSPU Negatives",
                muscleGroup: "Shoulders",
                cue: "Lower yourself over 4–5 seconds with complete control.",
                mode: .reps,
                targetSets: 4,
                targetReps: 5,
                targetHoldSeconds: nil,
                restSeconds: 90
            )
        ],

        "Arms": [
            ExerciseDefinition(
                name: "Chair Dips, Bent Knees",
                muscleGroup: "Arms",
                cue: "Place your hands on the edge of the chair and keep your elbows pointing backward.",
                mode: .reps,
                targetSets: 4,
                targetReps: 12,
                targetHoldSeconds: nil,
                restSeconds: 60
            ),
            ExerciseDefinition(
                name: "Chair Dips, Straight Legs",
                muscleGroup: "Arms",
                cue: "Keep your heels on the floor and your shoulders down.",
                mode: .reps,
                targetSets: 4,
                targetReps: 10,
                targetHoldSeconds: nil,
                restSeconds: 75
            ),
            ExerciseDefinition(
                name: "Between-Chair Dips",
                muscleGroup: "Arms",
                cue: "Lower yourself until your shoulders are below your elbows.",
                mode: .reps,
                targetSets: 4,
                targetReps: 8,
                targetHoldSeconds: nil,
                restSeconds: 75
            ),
            ExerciseDefinition(
                name: "Slow Dips",
                muscleGroup: "Arms",
                cue: "Take 4 seconds to lower yourself.",
                mode: .reps,
                targetSets: 4,
                targetReps: 6,
                targetHoldSeconds: nil,
                restSeconds: 90
            )
        ],

        "Back": [
            ExerciseDefinition(
                name: "Superman",
                muscleGroup: "Back",
                cue: "Lift your arms and legs and hold for 2 seconds.",
                mode: .reps,
                targetSets: 4,
                targetReps: 15,
                targetHoldSeconds: nil,
                restSeconds: 60
            ),
            ExerciseDefinition(
                name: "Inverted Row, High Body Position",
                muscleGroup: "Back",
                cue: "Under a sturdy table, pull your chest toward the edge.",
                mode: .reps,
                targetSets: 4,
                targetReps: 12,
                targetHoldSeconds: nil,
                restSeconds: 75
            ),
            ExerciseDefinition(
                name: "Inverted Row, Feet Forward",
                muscleGroup: "Back",
                cue: "A more horizontal position makes the exercise harder.",
                mode: .reps,
                targetSets: 4,
                targetReps: 10,
                targetHoldSeconds: nil,
                restSeconds: 75
            ),
            ExerciseDefinition(
                name: "Horizontal Inverted Row",
                muscleGroup: "Back",
                cue: "Keep your body parallel to the floor and rigid.",
                mode: .reps,
                targetSets: 4,
                targetReps: 10,
                targetHoldSeconds: nil,
                restSeconds: 90
            ),
            ExerciseDefinition(
                name: "One-Arm Row",
                muscleGroup: "Back",
                cue: "Maximize the tension on one side at a time.",
                mode: .reps,
                targetSets: 4,
                targetReps: 6,
                targetHoldSeconds: nil,
                restSeconds: 90
            )
        ],

        "Legs": [
            ExerciseDefinition(
                name: "Bodyweight Squats",
                muscleGroup: "Legs",
                cue: "Lower below parallel while keeping your back straight.",
                mode: .reps,
                targetSets: 4,
                targetReps: 15,
                targetHoldSeconds: nil,
                restSeconds: 60
            ),
            ExerciseDefinition(
                name: "Alternating Lunges",
                muscleGroup: "Legs",
                cue: "Keep your knee aligned under your hip and control the descent.",
                mode: .reps,
                targetSets: 4,
                targetReps: 12,
                targetHoldSeconds: nil,
                restSeconds: 75
            ),
            ExerciseDefinition(
                name: "Bulgarian Split Squats",
                muscleGroup: "Legs",
                cue: "Place your rear foot on an elevated surface and keep your weight on the front heel.",
                mode: .reps,
                targetSets: 4,
                targetReps: 10,
                targetHoldSeconds: nil,
                restSeconds: 90
            ),
            ExerciseDefinition(
                name: "Assisted Pistol Squats",
                muscleGroup: "Legs",
                cue: "Use one leg while lightly holding onto a stable support.",
                mode: .reps,
                targetSets: 4,
                targetReps: 8,
                targetHoldSeconds: nil,
                restSeconds: 90
            ),
            ExerciseDefinition(
                name: "Pistol Squats",
                muscleGroup: "Legs",
                cue: "Perform a full-depth single-leg squat.",
                mode: .reps,
                targetSets: 4,
                targetReps: 5,
                targetHoldSeconds: nil,
                restSeconds: 120
            )
        ],

        "Core": [
            ExerciseDefinition(
                name: "Plank",
                muscleGroup: "Core",
                cue: "Keep your body rigid and your glutes engaged.",
                mode: .hold,
                targetSets: 4,
                targetReps: nil,
                targetHoldSeconds: 40,
                restSeconds: 60
            ),
            ExerciseDefinition(
                name: "Hollow Hold",
                muscleGroup: "Core",
                cue: "Keep your lower back against the floor with your legs and shoulders lifted.",
                mode: .hold,
                targetSets: 4,
                targetReps: nil,
                targetHoldSeconds: 30,
                restSeconds: 60
            ),
            ExerciseDefinition(
                name: "Floor Leg Raises",
                muscleGroup: "Core",
                cue: "Keep your lower back pressed into the floor and lower your legs without arching.",
                mode: .reps,
                targetSets: 4,
                targetReps: 15,
                targetHoldSeconds: nil,
                restSeconds: 60
            ),
            ExerciseDefinition(
                name: "Hanging Knee Raises",
                muscleGroup: "Core",
                cue: "While hanging, bring your knees toward your chest without swinging.",
                mode: .reps,
                targetSets: 4,
                targetReps: 12,
                targetHoldSeconds: nil,
                restSeconds: 75
            ),
            ExerciseDefinition(
                name: "L-Sit",
                muscleGroup: "Core",
                cue: "Keep your legs straight and parallel to the floor with your shoulders down.",
                mode: .hold,
                targetSets: 4,
                targetReps: nil,
                targetHoldSeconds: 15,
                restSeconds: 90
            )
        ]
    ]

    static func exercise(for muscle: String, chainIndex: Int) -> ExerciseDefinition? {
        guard let chain = chains[muscle], !chain.isEmpty else {
            return nil
        }

        let index = min(max(chainIndex, 0), chain.count - 1)
        return chain[index]
    }

    static func chainLength(for muscle: String) -> Int {
        chains[muscle]?.count ?? 1
    }

    static func workout(
        for muscles: Set<String>,
        profile: UserProfile,
        level: TrainingLevel
    ) -> [ExerciseDefinition] {
        muscles
            .sorted()
            .compactMap { muscle in
                let progress = profile.trainingProgress[muscle]
                let chainIndex = progress?.chainIndex ?? level.startingChainOffset
                return exercise(for: muscle, chainIndex: chainIndex)
            }
    }
}
