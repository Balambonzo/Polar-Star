import Foundation

enum AdvancedWorkoutPlan {

    enum PullVariant: Hashable {
        case pullUps
        case hammerCurl
    }

    static func exercises(for weekday: Int, pullVariant: PullVariant = .pullUps) -> [ExerciseDefinition] {
        switch weekday {
        case 2: return monday
        case 3: return tuesday(variant: pullVariant)
        case 4: return wednesday
        case 5: return thursdayCircuit
        case 6: return friday
        default: return []   // Sabato/Domenica: giorno bonus, gestito col flusso libero
        }
    }

    static func dayLabel(for weekday: Int) -> String {
        switch weekday {
        case 2: return "Chest, Shoulders & Triceps"
        case 3: return "Back, Biceps & Core"
        case 4: return "Legs"
        case 5: return "Power Circuit"
        case 6: return "Arms"
        default: return "Bonus Day"
        }
    }

    // MARK: - Lunedì: petto, spalle, tricipiti

    static let monday: [ExerciseDefinition] = [
        ExerciseDefinition(name: "Push-Ups", muscleGroup: "Chest", cue: "Full range of motion, elbows at 45°.", mode: .reps, targetSets: 4, targetReps: 10, targetHoldSeconds: nil, restSeconds: 60),
        ExerciseDefinition(name: "Triceps Extension", muscleGroup: "Arms", cue: "Control the movement, focus on the triceps.", mode: .reps, targetSets: 4, targetReps: 10, targetHoldSeconds: nil, restSeconds: 60),
        ExerciseDefinition(name: "Chest Press", muscleGroup: "Chest", cue: "3x8 if heavy, 4x8 if light.", mode: .reps, targetSets: 3, targetReps: 8, targetHoldSeconds: nil, restSeconds: 90),
        ExerciseDefinition(name: "Shoulder Press", muscleGroup: "Shoulders", cue: "Press overhead with control, avoid arching your back.", mode: .reps, targetSets: 3, targetReps: 10, targetHoldSeconds: nil, restSeconds: 90)
    ]

    // MARK: - Martedì: schiena, bicipiti, core

    static func tuesday(variant: PullVariant) -> [ExerciseDefinition] {
        let pullExercise: ExerciseDefinition = {
            switch variant {
            case .pullUps:
                // AMRAP: uso 8 come target orientativo invece di lasciare
                // nil, così l'etichetta "Target: X reps" resta sensata.
                return ExerciseDefinition(name: "Pull-Ups", muscleGroup: "Back", cue: "As many reps as possible with good form — 8 is a solid benchmark.", mode: .reps, targetSets: 4, targetReps: 8, targetHoldSeconds: nil, restSeconds: 90)
            case .hammerCurl:
                return ExerciseDefinition(name: "Hammer Curl", muscleGroup: "Arms", cue: "Neutral grip, control the negative.", mode: .reps, targetSets: 3, targetReps: 12, targetHoldSeconds: nil, restSeconds: 60)
            }
        }()

        return [
            ExerciseDefinition(name: "Plank", muscleGroup: "Core", cue: "Keep your body rigid, glutes engaged.", mode: .hold, targetSets: 3, targetReps: nil, targetHoldSeconds: 40, restSeconds: 45),
            ExerciseDefinition(name: "Bicep Curls", muscleGroup: "Arms", cue: "Control the movement, no swinging.", mode: .reps, targetSets: 4, targetReps: 12, targetHoldSeconds: nil, restSeconds: 60),
            pullExercise,
            ExerciseDefinition(name: "Scissor Kicks", muscleGroup: "Core", cue: "Keep your lower back pressed into the floor.", mode: .hold, targetSets: 4, targetReps: nil, targetHoldSeconds: 30, restSeconds: 30)
        ]
    }

    // MARK: - Mercoledì: gambe

    static let wednesday: [ExerciseDefinition] = [
        ExerciseDefinition(name: "Bulgarian Split Squat", muscleGroup: "Legs", cue: "2 sets of 10 per side, control the descent.", mode: .reps, targetSets: 2, targetReps: 10, targetHoldSeconds: nil, restSeconds: 90),
        ExerciseDefinition(name: "Single-Leg Glute Bridge", muscleGroup: "Legs", cue: "2 sets of 12 per side, squeeze at the top.", mode: .reps, targetSets: 2, targetReps: 12, targetHoldSeconds: nil, restSeconds: 60),
        ExerciseDefinition(name: "Calf Raises", muscleGroup: "Legs", cue: "Full range of motion, pause at the top.", mode: .reps, targetSets: 3, targetReps: 20, targetHoldSeconds: nil, restSeconds: 45),
        ExerciseDefinition(name: "Squat", muscleGroup: "Legs", cue: "Or deadlift if you have improvised weight.", mode: .reps, targetSets: 4, targetReps: 10, targetHoldSeconds: nil, restSeconds: 90)
    ]

    // MARK: - Giovedì: potenza — circuito, 4 giri, 40s lavoro / 20s rest tra
    // esercizi, 60s rest tra un giro e l'altro. Modellato come 16 slot lineari.

    static let thursdayCircuit: [ExerciseDefinition] = {
        let roundExercises: [(name: String, muscleGroup: String, cue: String)] = [
            ("Burpee", "Core", "Full body movement, keep a steady pace."),
            ("Jump Squat", "Legs", "Land soft, chest up."),
            ("Alternating Push-Ups", "Chest", "One hand elevated at a time, alternate sides."),
            ("Shoulder Tap Plank", "Core", "Keep your hips still while tapping.")
        ]

        var result: [ExerciseDefinition] = []
        for round in 1...4 {
            for (index, ex) in roundExercises.enumerated() {
                let isLastOfRound = index == roundExercises.count - 1
                result.append(
                    ExerciseDefinition(
                        name: "\(ex.name) (Round \(round)/4)",
                        muscleGroup: ex.muscleGroup,
                        cue: ex.cue,
                        mode: .hold,
                        targetSets: 1,
                        targetReps: nil,
                        targetHoldSeconds: 40,
                        restSeconds: isLastOfRound ? 60 : 20
                    )
                )
            }
        }
        return result
    }()

    // MARK: - Venerdì: braccia

    static let friday: [ExerciseDefinition] = [
        ExerciseDefinition(name: "Lateral Raises", muscleGroup: "Shoulders", cue: "Lead with your elbows, avoid swinging.", mode: .reps, targetSets: 4, targetReps: 15, targetHoldSeconds: nil, restSeconds: 60),
        ExerciseDefinition(name: "Bench Dips", muscleGroup: "Arms", cue: "As many reps as possible — 12 is a solid benchmark.", mode: .reps, targetSets: 4, targetReps: 12, targetHoldSeconds: nil, restSeconds: 90),
        ExerciseDefinition(name: "Bent-Over Row", muscleGroup: "Back", cue: "Or one arm at a time, 2x10 each side.", mode: .reps, targetSets: 4, targetReps: 10, targetHoldSeconds: nil, restSeconds: 60),
        ExerciseDefinition(name: "Floor Chest Flyes", muscleGroup: "Chest", cue: "Wide arc, control the stretch.", mode: .reps, targetSets: 3, targetReps: 12, targetHoldSeconds: nil, restSeconds: 60)
    ]
}
