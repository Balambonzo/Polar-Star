//TrainingWorkoutView.swift
import SwiftUI
import SwiftData

struct TrainingWorkoutView: View {
    @Bindable var controller: TrainingWorkoutController

    @FocusState private var focusedField: InputField?

    private enum InputField {
        case reps
        case seconds
        case weight
    }

    let trainingEntry: TrainingEntry
    let onFinish: () -> Void
    let onCancel: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var repsText = ""
    @State private var secondsText = ""
    @State private var weightText = ""
    @State private var rpe: Double = 8
    @State private var showExitConfirmation = false
    

    private var currentExerciseEntity: TrainingExercise? {
        guard trainingEntry.exercises.indices.contains(controller.currentExerciseIndex) else {
            return nil
        }

        return trainingEntry.exercises
            .sorted { $0.order < $1.order }[controller.currentExerciseIndex]
    }

    private var currentExercise: ExerciseDefinition? {
        controller.currentExercise
    }

    var body: some View {
        ZStack {
            StarfieldBackground()
                .ignoresSafeArea()

            Group {
                if controller.phase == .resting {
                    restView
                } else if controller.phase == .completed {
                    completedView
                } else if let exercise = currentExercise {
                    exerciseView(exercise)
                }
            }
        }
        .contentShape(Rectangle())
        .background {
            // Copre anche la fase di recupero, che non usa una ScrollView.
            // È solo diagnostica: verrà rimossa insieme alla sonda quando
            // avremo il tracciato dal dispositivo.
//            RenderMotionProbe(name: "Training workout root")
//                .frame(width: 1, height: 1)
//                .allowsHitTesting(false)
       }
        .onTapGesture {
            focusedField = nil
            hideKeyboard()
        }
        .onAppear {
                    prepareInputs()
                    focusedField = nil
                    hideKeyboard()
                    controller.refreshAfterForeground()
                }
        .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        controller.refreshAfterForeground()
                    } else {
                        controller.pauseTickingForBackground()
                    }
                }
        .onChange(of: controller.isHoldTimerActive) { _, isActive in
            if !isActive, secondsText.isEmpty, let target = currentExercise?.targetHoldSeconds {
                secondsText = "\(target)"
            }
        }
        .confirmationDialog(
            "Exit this workout?",
            isPresented: $showExitConfirmation,
            titleVisibility: .visible
        ) {
            Button("Exit workout", role: .destructive) {
                onCancel()
            }
            Button("Keep training", role: .cancel) {}
        } message: {
            Text("Your progress on this session will be lost.")
        }
    }

    // MARK: - Exercise

    private func exerciseView(_ exercise: ExerciseDefinition) -> some View {
        ScrollView {
            VStack(spacing: 18) {

                // Header
                HStack {
                    Text(exercise.muscleGroup)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.orange)

                    Spacer()

                    Text(
                        "Set \(controller.currentSetNumber) / \(exercise.targetSets)"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                }
                
                ProgressView(value: controller.progress)
                                    .tint(.orange)

                // Exercise name
                Text(exercise.name)
                    .font(.system(
                        size: 30,
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 600)

                // Exercise cue
                Text(exercise.cue)
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)

                // Target
                if exercise.mode == .reps {
                    targetText(
                        "Target: \(exercise.targetReps ?? 0) reps"
                    )

                    inputField(
                        title: "Reps",
                        text: $repsText,
                        keyboard: .numberPad
                    )
                } else {
                    targetText(
                        "Target: \(exercise.targetHoldSeconds ?? 0) seconds"
                    )

                    // Countdown automatico — vibra da solo a fine hold
                    VStack(spacing: 4) {
                        Text(controller.holdTimeLabel)
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(
                                controller.isHoldTimerActive ? Theme.textPrimary : Theme.success
                            )

                        if !controller.isHoldTimerActive {
                            Text("Time's up — adjust below if needed")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                    .glassCard()

                    inputField(
                        title: "Seconds",
                        text: $secondsText,
                        keyboard: .numberPad
                    )
                }
                // Weight
                inputField(
                    title: "Weight (kg, optional)",
                    text: $weightText,
                    keyboard: .decimalPad
                )

                // RPE
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("RPE")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)

                        Spacer()

                        Text(String(format: "%.1f", rpe))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.orange)
                    }

                    Slider(
                        value: $rpe,
                        in: 1...10,
                        step: 0.5
                    )
                    .tint(.orange)
                }
                .glassCard()

                // Complete
                Button {
                    saveCurrentSet()
                } label: {
                    Label(
                        exercise.mode == .reps
                            ? "Complete set"
                            : "Complete hold",
                        systemImage: "checkmark"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .foregroundStyle(.white)
                    .background(
                        canSubmit
                            ? Color.orange
                            : Color.gray.opacity(0.35),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                }
                .disabled(!canSubmit)

                // Exit
                Button {
                    Haptics.tap()
                    showExitConfirmation = true   // ← era: onCancel()
                } label: {
                    Text("Exit workout")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.red)
                        .padding(.vertical, 6)
                }
            }
            .frame(maxWidth: 620)
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .transaction {
            $0.scrollContentOffsetAdjustmentBehavior = .disabled
        }
    }

    // MARK: - Rest

    private var restView: some View {
        VStack(spacing: 20) {
            Text("REST")
                .font(.caption.weight(.bold))
                .foregroundStyle(.orange)

            Text(controller.restTimeLabel)
                .font(.system(
                    size: 54,
                    weight: .bold,
                    design: .rounded
                ))
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)

            if let next = currentExercise {
                VStack(spacing: 5) {
                    Text("Next")
                        .font(.caption)
                        .foregroundStyle(Theme.textTertiary)

                    Text(next.name)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                }
            }

            HStack(spacing: 10) {
                            Button {
                                Haptics.tap()
                                controller.addRestTime(15)
                            } label: {
                                Text("+15s")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
                                    .foregroundStyle(.orange)
                                    .background(
                                        Color.orange.opacity(0.12),
                                        in: RoundedRectangle(cornerRadius: 16)
                                    )
                            }
                            Button {
                                Haptics.tap()
                                controller.skipRest()
                            } label: {
                                Text("Skip rest")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
                                    .foregroundStyle(.white)
                                    .background(
                                        Color.orange,
                                        in: RoundedRectangle(cornerRadius: 16)
                                    )
                            }
                        }
        }
        .glassCard()
        .frame(maxWidth: 500)
        .padding(.horizontal, 24)
    }

    // MARK: - Completed

    private var completedView: some View {
        let allSets = trainingEntry.exercises
            .flatMap(\.sets)

        let volume = allSets.reduce(0.0) { total, set in
            guard let reps = set.reps,
                  let weight = set.weight else {
                return total
            }

            return total + Double(reps) * weight
        }

        return VStack(spacing: 18) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 52))
                .foregroundStyle(.green)

            Text("Workout complete")
                .font(.title2.bold())
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)

            Text("\(allSets.count) real sets completed")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)

            if volume > 0 {
                Text("\(formatVolume(volume)) kg volume")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
            }

            Button {
                Haptics.success()
                onFinish()
            } label: {
                Text("Finish workout")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .foregroundStyle(.white)
                    .background(
                        Color.orange,
                        in: RoundedRectangle(cornerRadius: 16)
                    )
            }
        }
        .glassCard()
        .frame(maxWidth: 500)
        .padding(.horizontal, 24)
    }

    // MARK: - Validation

    private var canSubmit: Bool {
        guard let exercise = currentExercise else {
            return false
        }

        if exercise.mode == .reps {
            guard let reps = Int(repsText), reps > 0 else {
                return false
            }
        } else {
            guard let seconds = Int(secondsText), seconds > 0 else {
                return false
            }
        }

        return rpe >= 1 && rpe <= 10
    }

    // MARK: - Save

    private func saveCurrentSet() {
        guard let exercise = currentExercise,
              let exerciseEntity = currentExerciseEntity else {
            return
        }

        let weight = Double(
            weightText.replacingOccurrences(
                of: ",",
                with: "."
            )
        )

        let reps: Int?
        let durationSeconds: Int?

        if exercise.mode == .reps {
            guard let parsedReps = Int(repsText),
                  parsedReps > 0 else {
                return
            }

            reps = parsedReps
            durationSeconds = nil
        } else {
            guard let parsedSeconds = Int(secondsText),
                  parsedSeconds > 0 else {
                return
            }

            reps = nil
            durationSeconds = parsedSeconds
        }

        let set = TrainingSet(
            reps: reps,
            weight: weight,
            rpe: rpe,
            durationSeconds: durationSeconds,
            setNumber: controller.currentSetNumber
        )

        exerciseEntity.sets.append(set)
        modelContext.insert(set)

        try? modelContext.save()

        Haptics.success()

        focusedField = nil
        hideKeyboard()

        clearInputs()
        controller.completeCurrentSet()
    }

    // MARK: - Inputs

    private func prepareInputs() {
        repsText = ""
        secondsText = ""
        weightText = ""
        rpe = 8
    }

    private func clearInputs() {
        repsText = ""
        secondsText = ""
        weightText = ""
        rpe = 8
    }

    // MARK: - Components

    private func targetText(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.orange)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Color.orange.opacity(0.12),
                in: Capsule()
            )
    }

    private func inputField(
        title: String,
        text: Binding<String>,
        keyboard: UIKeyboardType
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)

            TextField(title, text: text)
                .keyboardType(keyboard)
                .focused(
                    $focusedField,
                    equals: inputFieldFor(title)
                )
                .submitLabel(.done)
                .onSubmit {
                    focusedField = nil
                    hideKeyboard()
                }
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .padding()
                .background(
                    Theme.card,
                    in: RoundedRectangle(cornerRadius: 12)
                )
        }
    }

    private func inputFieldFor(
        _ title: String
    ) -> InputField? {
        switch title {
        case "Reps":
            return .reps

        case "Seconds":
            return .seconds

        case "Weight (kg, optional)":
            return .weight

        default:
            return nil
        }
    }

    // MARK: - Helpers

    private func formatVolume(_ volume: Double) -> String {
        if volume.rounded() == volume {
            return "\(Int(volume))"
        }

        return String(format: "%.1f", volume)
    }

    private func hideKeyboard() {
        #if os(iOS)
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
        #endif
    }
}
