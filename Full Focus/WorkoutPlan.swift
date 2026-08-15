import Foundation

enum TrainingLevel: String, CaseIterable, Codable {
    case beginner, intermediate, advanced

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }

    var minimumSessionMinutes: Int {
        switch self {
        case .beginner: return 15
        case .intermediate: return 20
        case .advanced: return 25
        }
    }

    /// Starting point in the progression chain if you don't yet
    /// have any history for that muscle group.
    var startingChainOffset: Int {
        switch self {
        case .beginner: return 0
        case .intermediate: return 1
        case .advanced: return 2
        }
    }
}

enum ExerciseMode {
    case reps, hold
}

struct Exercise {
    let name: String
    let cue: String
    let mode: ExerciseMode
    let min: Int
    let max: Int
}

/// For each muscle group, a chain of variations from easiest to
/// hardest — the user progresses through the chain over time
/// instead of choosing a fixed "level".
enum WorkoutPlan {

    static let allMuscleGroups = [
        "Chest", "Shoulders", "Arms", "Back", "Legs", "Core"
    ]

    static let chains: [String: [Exercise]] = [
        "Chest": [
            Exercise(name: "Wall Push-Ups", cue: "Keep your body straight, stabilize your shoulder blades, and lower yourself with control.", mode: .reps, min: 12, max: 20),
            Exercise(name: "Incline Push-Ups", cue: "Place your hands on an elevated surface, keeping your elbows at 45°.", mode: .reps, min: 10, max: 16),
            Exercise(name: "Knee Push-Ups", cue: "Keep a straight line from your knees to your head.", mode: .reps, min: 8, max: 15),
            Exercise(name: "Full Push-Ups", cue: "Lower your chest toward the floor while keeping your body rigid like a plank.", mode: .reps, min: 8, max: 15),
            Exercise(name: "Diamond Push-Ups", cue: "Place your hands in a diamond shape underneath your sternum.", mode: .reps, min: 6, max: 12),
            Exercise(name: "Decline Push-Ups", cue: "Place your feet on an elevated surface to increase the load on your upper chest.", mode: .reps, min: 8, max: 14)
        ],
        "Shoulders": [
            Exercise(name: "Pike Push-Ups", cue: "Keep your hips high in a V position and lower your head toward the floor.", mode: .reps, min: 8, max: 14),
            Exercise(name: "Feet-Elevated Pike Push-Ups", cue: "A more vertical position places more load on your shoulders.", mode: .reps, min: 6, max: 12),
            Exercise(name: "Wall Handstand Hold", cue: "Keep your body aligned with your back against the wall.", mode: .hold, min: 20, max: 50),
            Exercise(name: "Wall HSPU Negatives", cue: "Lower yourself over 4–5 seconds with complete control.", mode: .reps, min: 3, max: 8)
        ],
        "Arms": [
            Exercise(name: "Chair Dips, Bent Knees", cue: "Place your hands on the edge of the chair and keep your elbows pointing backward.", mode: .reps, min: 8, max: 15),
            Exercise(name: "Chair Dips, Straight Legs", cue: "Keep your heels on the floor and your shoulders down.", mode: .reps, min: 8, max: 15),
            Exercise(name: "Between-Chair Dips", cue: "Lower yourself until your shoulders are below your elbows.", mode: .reps, min: 6, max: 12),
            Exercise(name: "Slow Dips", cue: "Take 4 seconds to lower yourself.", mode: .reps, min: 5, max: 10)
        ],
        "Back": [
            Exercise(name: "Superman", cue: "Lift your arms and legs and hold for 2 seconds.", mode: .reps, min: 10, max: 20),
            Exercise(name: "Inverted Row, High Body Position", cue: "Under a sturdy table, pull your chest toward the edge.", mode: .reps, min: 10, max: 16),
            Exercise(name: "Inverted Row, Feet Forward", cue: "A more horizontal position makes the exercise harder.", mode: .reps, min: 8, max: 15),
            Exercise(name: "Horizontal Inverted Row", cue: "Keep your body parallel to the floor and rigid.", mode: .reps, min: 8, max: 14),
            Exercise(name: "One-Arm Row", cue: "Maximize the tension on one side at a time.", mode: .reps, min: 4, max: 8)
        ],
        "Legs": [
            Exercise(name: "Bodyweight Squats", cue: "Lower below parallel while keeping your back straight.", mode: .reps, min: 12, max: 22),
            Exercise(name: "Alternating Lunges", cue: "Keep your knee aligned under your hip and control the descent.", mode: .reps, min: 10, max: 18),
            Exercise(name: "Bulgarian Split Squats", cue: "Place your rear foot on an elevated surface and keep your weight on the front heel.", mode: .reps, min: 8, max: 14),
            Exercise(name: "Assisted Pistol Squats", cue: "Use one leg while lightly holding onto a stable support.", mode: .reps, min: 5, max: 10),
            Exercise(name: "Pistol Squats", cue: "Perform a full-depth single-leg squat.", mode: .reps, min: 3, max: 8)
        ],
        "Core": [
            Exercise(name: "Plank", cue: "Keep your body rigid and your glutes engaged.", mode: .hold, min: 20, max: 60),
            Exercise(name: "Hollow Hold", cue: "Keep your lower back against the floor with your legs and shoulders lifted.", mode: .hold, min: 15, max: 45),
            Exercise(name: "Floor Leg Raises", cue: "Keep your lower back pressed into the floor and lower your legs without arching.", mode: .reps, min: 10, max: 18),
            Exercise(name: "Hanging Knee Raises", cue: "While hanging, bring your knees toward your chest without swinging.", mode: .reps, min: 8, max: 15),
            Exercise(name: "L-Sit", cue: "Keep your legs straight and parallel to the floor with your shoulders down.", mode: .hold, min: 8, max: 25)
        ]
    ]

    static func exercise(for muscle: String, chainIndex: Int) -> Exercise? {
        guard let chain = chains[muscle] else { return nil }
        let idx = min(max(chainIndex, 0), chain.count - 1)
        return chain[idx]
    }

    static func chainLength(for muscle: String) -> Int {
        chains[muscle]?.count ?? 1
    }
}
