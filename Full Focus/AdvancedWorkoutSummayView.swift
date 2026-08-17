import SwiftUI

struct AdvancedWorkoutSummaryView: View {
    let onStart: ([ExerciseDefinition]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pullVariant: AdvancedWorkoutPlan.PullVariant = .pullUps

    private var weekday: Int {
        Calendar.current.component(.weekday, from: Date())
    }

    private var isTuesday: Bool { weekday == 3 }

    private var exercises: [ExerciseDefinition] {
        AdvancedWorkoutPlan.exercises(for: weekday, pullVariant: pullVariant)
    }

    private var totalSets: Int {
        exercises.reduce(0) { $0 + $1.targetSets }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        header

                        if isTuesday {
                            VStack(spacing: 8) {
                                Text("Choose your pull exercise")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                                Picker("Pull exercise", selection: $pullVariant) {
                                    Text("Pull-Ups").tag(AdvancedWorkoutPlan.PullVariant.pullUps)
                                    Text("Hammer Curl").tag(AdvancedWorkoutPlan.PullVariant.hammerCurl)
                                }
                                .pickerStyle(.segmented)
                            }
                            .padding(.horizontal, 4)
                        }

                        ForEach(Array(exercises.enumerated()), id: \.offset) { index, exercise in
                            exerciseCard(exercise, index: index)
                        }

                        Button {
                            Haptics.action()
                            onStart(exercises)
                        } label: {
                            Label("Start training", systemImage: "figure.strengthtraining.traditional")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundStyle(.white)
                                .background(Color.orange, in: RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                .transaction {
                    $0.scrollContentOffsetAdjustmentBehavior = .disabled
                }
            }
            .navigationTitle("Scheda by Elis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }.tint(.orange)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text(AdvancedWorkoutPlan.dayLabel(for: weekday))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)   // ← aggiungi questa
                .frame(maxWidth: .infinity)         // ← e questa

            Text("\(exercises.count) exercises • \(totalSets) total sets")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)

            Text("Each set will record your actual reps, weight and RPE.")
                .font(.caption)
                .foregroundStyle(.orange)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 16)
    }

    private func exerciseCard(_ exercise: ExerciseDefinition, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(index + 1)")
                    .font(.caption.weight(.bold))
                    .frame(width: 26, height: 26)
                    .foregroundStyle(.white)
                    .background(Color.orange, in: Circle())

                Text(exercise.muscleGroup)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)

                Spacer()
            }

            Text(exercise.name)
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            Text(exercise.cue)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)

            HStack(spacing: 8) {
                infoPill(text: "\(exercise.targetSets) sets", icon: "square.stack")

                if exercise.mode == .reps {
                    infoPill(text: "\(exercise.targetReps ?? 0) reps", icon: "repeat")
                } else {
                    infoPill(text: "\(exercise.targetHoldSeconds ?? 0)s", icon: "timer")
                }

                infoPill(text: "\(exercise.restSeconds)s rest", icon: "pause.circle")
            }
        }
        .padding()
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
    }

    private func infoPill(text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(Theme.cardBorder.opacity(0.35), in: Capsule())
    }
}
