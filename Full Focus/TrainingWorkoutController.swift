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
    
    private(set) var holdRemainingSeconds: Int = 0
    private(set) var isHoldTimerActive: Bool = false

    private var holdTimer: Timer?
    private var holdEndsAt: Date?

    private var restTimer: Timer?
    private var restEndsAt: Date?

    init(exercises: [ExerciseDefinition]) {
        self.exercises = exercises
    }

    deinit {
        restTimer?.invalidate()
        holdTimer?.invalidate()
    }

    func start() {
        currentExerciseIndex = 0
        currentSetIndex = 0
        completedSetCount = 0
        restRemainingSeconds = 0
        isCompleted = false
        enterPerformingSet()
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
    
    var holdTimeLabel: String {
        let minutes = holdRemainingSeconds / 60
        let seconds = holdRemainingSeconds % 60
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
        enterPerformingSet()
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
        if phase == .resting, let restEndsAt {
            let remaining = Int(ceil(restEndsAt.timeIntervalSinceNow))
            if remaining <= 0 {
                restRemainingSeconds = 0
                stopRestTimer()
                enterPerformingSet()   // ← era: phase = .performingSet
            } else {
                restRemainingSeconds = remaining
                if restTimer == nil {
                    startTicking()
                }
            }
        }

        if isHoldTimerActive, let holdEndsAt {
            let remaining = Int(ceil(holdEndsAt.timeIntervalSinceNow))
            if remaining <= 0 {
                holdRemainingSeconds = 0
                stopHoldTimer()
            } else {
                holdRemainingSeconds = remaining
                if holdTimer == nil {
                    startHoldTicking()
                }
            }
        }
    }

    func pauseTickingForBackground() {
        restTimer?.invalidate()
        restTimer = nil
        holdTimer?.invalidate()
        holdTimer = nil
    }

    private func startRest(seconds: Int) {
        restTimer?.invalidate()   // fermo solo il Timer vecchio, se esisteva
        restTimer = nil
        phase = .resting
        restRemainingSeconds = max(1, seconds)
        restEndsAt = Date().addingTimeInterval(TimeInterval(restRemainingSeconds))
        startTicking()
    }
    
    private func enterPerformingSet() {
        phase = .performingSet
        if let exercise = currentExercise,
           exercise.mode == .hold,
           let target = exercise.targetHoldSeconds {
            startHoldTimer(seconds: target)
        } else {
            stopHoldTimer()
        }
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
            enterPerformingSet()   // ← era: phase = .performingSet
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
    
    private func startHoldTimer(seconds: Int) {
        holdTimer?.invalidate()
        holdTimer = nil
        holdRemainingSeconds = max(1, seconds)
        holdEndsAt = Date().addingTimeInterval(TimeInterval(holdRemainingSeconds))
        isHoldTimerActive = true
        startHoldTicking()
    }

    private func startHoldTicking() {
        guard holdTimer == nil else { return }
        holdTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tickHold()
        }
    }

    private func tickHold() {
        guard let holdEndsAt else {
            stopHoldTimer()
            return
        }
        let remaining = Int(ceil(holdEndsAt.timeIntervalSinceNow))
        if remaining <= 0 {
            holdRemainingSeconds = 0
            stopHoldTimer()
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        } else {
            holdRemainingSeconds = remaining
        }
    }

    private func stopHoldTimer() {
        holdTimer?.invalidate()
        holdTimer = nil
        holdEndsAt = nil
        isHoldTimerActive = false
    }

    func cancel() {
        stopRestTimer()
        stopHoldTimer()
        phase = .completed
        isCompleted = false
    }
}
