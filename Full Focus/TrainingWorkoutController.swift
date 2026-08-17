import Foundation
import Observation
import AudioToolbox

enum TrainingPhase {
    case performingSet
    case resting
    case completed
}

@Observable
final class TrainingWorkoutController {

    let exercises: [ExerciseDefinition]

    private(set) var currentExerciseIndex: Int = 0
    private(set) var currentSetIndex: Int = 0
    private(set) var completedSetCount: Int = 0

    private(set) var phase: TrainingPhase = .performingSet
    private(set) var restRemainingSeconds: Int = 0
    private(set) var isCompleted: Bool = false

    private var restTimer: Timer?
    private var restEndsAt: Date?

    init(exercises: [ExerciseDefinition]) {
        self.exercises = exercises
    }

    deinit {
        restTimer?.invalidate()
    }

    func start() {
        currentExerciseIndex = 0
        currentSetIndex = 0
        completedSetCount = 0
        phase = .performingSet
        restRemainingSeconds = 0
        isCompleted = false
    }

    var currentExercise: ExerciseDefinition? {
        guard exercises.indices.contains(currentExerciseIndex) else { return nil }
        return exercises[currentExerciseIndex]
    }

    var currentSetNumber: Int { currentSetIndex + 1 }

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.targetSets }
    }

    var progress: Double {
        guard totalSets > 0 else { return 0 }
        return Double(completedSetCount) / Double(totalSets)
    }

    var restTimeLabel: String {
        let minutes = restRemainingSeconds / 60
        let seconds = restRemainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func completeCurrentSet() {
        guard phase == .performingSet, let exercise = currentExercise else { return }

        completedSetCount += 1

        let isLastSetOfExercise = currentSetIndex >= exercise.targetSets - 1
        let isLastExercise = currentExerciseIndex >= exercises.count - 1

        if isLastSetOfExercise && isLastExercise {
            phase = .completed
            isCompleted = true
            stopRestTimer()
            return
        }

        if isLastSetOfExercise {
            currentExerciseIndex += 1
            currentSetIndex = 0
        } else {
            currentSetIndex += 1
        }

        startRest(seconds: exercise.restSeconds)
    }

    func skipRest() {
        guard phase == .resting else { return }
        stopRestTimer()
        restRemainingSeconds = 0
        phase = .performingSet
    }

    /// Aggiunge secondi al recupero in corso — utile se vuoi restare
    /// fermo un po' di più prima della serie successiva.
    func addRestTime(_ seconds: Int) {
        guard phase == .resting, let restEndsAt else { return }
        self.restEndsAt = restEndsAt.addingTimeInterval(TimeInterval(seconds))
        restRemainingSeconds += seconds
    }

    /// Da chiamare quando l'app torna in primo piano (dalla vista, tramite
    /// scenePhase) — recupera il tempo di recupero passato mentre l'app
    /// era sospesa, invece di restare congelata per sempre.
    func refreshAfterForeground() {
        guard phase == .resting, let restEndsAt else { return }
        let remaining = Int(ceil(restEndsAt.timeIntervalSinceNow))
        if remaining <= 0 {
            restRemainingSeconds = 0
            stopRestTimer()
            phase = .performingSet
        } else {
            restRemainingSeconds = remaining
            if restTimer == nil {
                startTicking()
            }
        }
    }

    func pauseTickingForBackground() {
        restTimer?.invalidate()
        restTimer = nil
    }

    private func startRest(seconds: Int) {
        restTimer?.invalidate()   // fermo solo il Timer vecchio, se esisteva
        restTimer = nil
        phase = .resting
        restRemainingSeconds = max(1, seconds)
        restEndsAt = Date().addingTimeInterval(TimeInterval(restRemainingSeconds))
        startTicking()
    }

    private func startTicking() {
        guard restTimer == nil else { return }
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tickRest()
        }
    }

    private func tickRest() {
        guard let restEndsAt else {
            stopRestTimer()
            return
        }
        let remaining = Int(ceil(restEndsAt.timeIntervalSinceNow))
        if remaining <= 0 {
            restRemainingSeconds = 0
            stopRestTimer()
            phase = .performingSet
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        } else {
            restRemainingSeconds = remaining
        }
    }

    private func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        restEndsAt = nil
    }

    func cancel() {
        stopRestTimer()
        phase = .completed
        isCompleted = false
    }
}
