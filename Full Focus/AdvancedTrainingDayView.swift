import SwiftUI

struct AdvancedTrainingDayView: View {
    let onStart: ([ExerciseDefinition]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pullVariant: AdvancedWorkoutPlan.PullVariant = .pullUps
    @State private var showPreview = false

    private var weekday: Int {
        Calendar.current.component(.weekday, from: Date())
    }

    private var isTuesday: Bool { weekday == 3 }

    private var exercises: [ExerciseDefinition] {
        AdvancedWorkoutPlan.exercises(for: weekday, pullVariant: pullVariant)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        Text(AdvancedWorkoutPlan.dayLabel(for: weekday))
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                            .padding(.top, 20)

                        Text("Today's fixed program.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)

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
                            .padding(.horizontal, 32)
                        }

                        Button {
                            Haptics.action()
                            showPreview = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Workout ready")
                                        .font(.headline)
                                        .foregroundStyle(Theme.textPrimary)
                                    Text("\(exercises.count) exercises")
                                        .font(.caption)
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.headline)
                                    .foregroundStyle(.orange)
                            }
                            .padding()
                            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)

                        Spacer(minLength: 30)
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
                    Button("Close") { dismiss() }.tint(.orange)
                }
            }
            .navigationDestination(isPresented: $showPreview) {
                TrainingWorkoutPreviewView(exercises: exercises, onStart: {
                    onStart(exercises)
                })
            }
        }
    }
}
