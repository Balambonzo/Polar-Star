//TrainingSessionSetupView.swift
import SwiftUI

struct TrainingSessionSetupView: View {
    let profile: UserProfile
    let level: TrainingLevel
    let onStart: ([ExerciseDefinition]) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedMuscles: Set<String> = []
    @State private var showWorkoutPreview = false
    @State private var showFront = true   // ← nuovo

    private var selectedExercises: [ExerciseDefinition] {
        WorkoutPlan.workout(
            for: selectedMuscles,
            profile: profile,
            level: level
        )
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

                        Text("Choose the muscle groups you want to train.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Picker("", selection: $showFront) {
                            Text("Front view").tag(true)
                            Text("Back View").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 200)

                        InteractiveBodyFigureView(
                            levels: Dictionary(
                                uniqueKeysWithValues: WorkoutPlan.allMuscleGroups.map {
                                    ($0, 1)
                                }
                            ),
                            selected: selectedMuscles,
                            onTap: toggle,
                            showFront: showFront   // ← nuovo
                        )
                        
                        if !selectedExercises.isEmpty {
                            Button {
                                Haptics.action()
                                showWorkoutPreview = true
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Workout ready")
                                            .font(.headline)
                                            .foregroundStyle(Theme.textPrimary)

                                        Text(
                                            "\(selectedExercises.count) exercises • \(totalSets) sets"
                                        )
                                        .font(.caption)
                                        .foregroundStyle(Theme.textSecondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.headline)
                                        .foregroundStyle(.orange)
                                }
                                .padding()
                                .background(
                                    Theme.card,
                                    in: RoundedRectangle(cornerRadius: 16)
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 30)
                    }
                    .background {
//                        RenderMotionProbe(name: "Training setup scroll content")
//                            .frame(width: 1, height: 1)
//                            .allowsHitTesting(false)
                    }
                }
                .transaction {
                    $0.scrollContentOffsetAdjustmentBehavior = .disabled
                }
            }
            .navigationTitle("Training")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .tint(.orange)
                }
            }
            .navigationDestination(isPresented: $showWorkoutPreview) {
                TrainingWorkoutPreviewView(
                    exercises: selectedExercises,
                    onStart: {
                        onStart(selectedExercises)
                    }
                )
            }
        }
    }

    private var totalSets: Int {
        selectedExercises.reduce(0) {
            $0 + $1.targetSets
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
