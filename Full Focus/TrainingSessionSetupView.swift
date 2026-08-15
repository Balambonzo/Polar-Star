import SwiftUI

struct TrainingSessionSetupView: View {
    let profile: UserProfile
    let level: TrainingLevel
    let minimumMinutes: Int
    let onStart: (Set<String>, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedMuscles: Set<String> = []
    @State private var selectedMinutes: Int

    init(profile: UserProfile, level: TrainingLevel, minimumMinutes: Int, onStart: @escaping (Set<String>, Int) -> Void) {
        self.profile = profile
        self.level = level
        self.minimumMinutes = minimumMinutes
        self.onStart = onStart
        _selectedMinutes = State(initialValue: minimumMinutes)
    }

    private func currentExercise(for muscle: String) -> Exercise? {
        let progress = profile.trainingProgress[muscle]
        let index = progress?.chainIndex ?? level.startingChainOffset
        return WorkoutPlan.exercise(for: muscle, chainIndex: index)
    }

    private func chainProgressLabel(for muscle: String) -> String {
        let progress = profile.trainingProgress[muscle]
        let index = progress?.chainIndex ?? level.startingChainOffset
        let total = WorkoutPlan.chainLength(for: muscle)
        return "\(index + 1)/\(total)"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        Text("What do you want to train today?")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                            .padding(.top, 20)

                        Text("Touch the body part you want to train, and we'll show you the exercises for each session.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        InteractiveBodyFigureView(
                            levels: Dictionary(uniqueKeysWithValues: WorkoutPlan.allMuscleGroups.map { ($0, 1) }),
                            selected: selectedMuscles,
                            onTap: toggle
                        )

                        if !selectedMuscles.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                ForEach(Array(selectedMuscles).sorted(), id: \.self) { muscle in
                                    if let exercise = currentExercise(for: muscle) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(muscle)
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundStyle(.orange)
                                                Spacer()
                                                Text(chainProgressLabel(for: muscle))
                                                    .font(.caption2)
                                                    .foregroundStyle(Theme.textTertiary)
                                            }
                                            Text(exercise.name)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(Theme.textPrimary)
                                            Text(exercise.cue)
                                                .font(.caption)
                                                .foregroundStyle(Theme.textSecondary)
                                            Text(exercise.mode == .hold ? "\(exercise.min)-\(exercise.max)s" : "\(exercise.min)-\(exercise.max) rip")
                                                .font(.caption2)
                                                .foregroundStyle(Theme.textTertiary)
                                        }
                                    }
                                }
                            }
                            .glassCard()
                            .padding(.horizontal, 20)

                            VStack(spacing: 8) {
                                Text("Today's workout")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.textSecondary)
                                Picker("Time", selection: $selectedMinutes) {
                                    ForEach(Array(stride(from: minimumMinutes, through: minimumMinutes + 60, by: 5)), id: \.self) { m in
                                        Text("\(m) min").tag(m)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 100)
                            }

                            Button {
                                onStart(selectedMuscles, selectedMinutes)
                                Haptics.action()
                            } label: {
                                Label("Start training!", systemImage: "figure.strengthtraining.traditional")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .foregroundStyle(.white)
                                    .background(Color.orange, in: RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: .orange.opacity(0.35), radius: 14, y: 6)
                            }
                            .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 30)
                    }
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle("Training")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .tint(.orange)
                }
            }
        }
    }

    private func toggle(_ muscle: String) {
        if selectedMuscles.contains(muscle) {
            selectedMuscles.remove(muscle)
        } else {
            selectedMuscles.insert(muscle)
        }
    }
}
