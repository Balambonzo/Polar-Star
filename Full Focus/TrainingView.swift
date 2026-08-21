//TrainingView.swift
import SwiftUI
import SwiftData

struct TrainingView: View {
    @Query private var trainingEntries: [TrainingEntry]
    @Query private var profiles: [UserProfile]   // ← nuovo

    @State private var showFront = true

    private var completedEntries: [TrainingEntry] {
        trainingEntries.filter(\.isCompleted)
    }

    private var weeklySets: [String: Double] {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let daysSinceMonday = (weekday + 5) % 7

        guard let monday = calendar.date(
            byAdding: .day,
            value: -daysSinceMonday,
            to: calendar.startOfDay(for: now)
        ) else {
            return [:]
        }

        var counts: [String: Int] = [:]

        for entry in completedEntries where entry.date >= monday {
            for exercise in entry.exercises {
                counts[exercise.muscleGroup, default: 0] += exercise.sets.count
            }
        }

        return counts.mapValues(Double.init)
    }

    private var weeklyVolume: [String: Double] {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let daysSinceMonday = (weekday + 5) % 7

        guard let monday = calendar.date(
            byAdding: .day,
            value: -daysSinceMonday,
            to: calendar.startOfDay(for: now)
        ) else {
            return [:]
        }

        var result: [String: Double] = [:]

        for entry in completedEntries where entry.date >= monday {
            for exercise in entry.exercises {
                for set in exercise.sets {
                    guard let reps = set.reps,
                          let weight = set.weight else {
                        continue
                    }

                    result[exercise.muscleGroup, default: 0] +=
                        Double(reps) * weight
                }
            }
        }

        return result
    }
    

    private var totalWeeklySets: Int {
        Int(weeklySets.values.reduce(0, +))
    }

    private var totalWeeklyVolume: Double {
        weeklyVolume.values.reduce(0, +)
    }
    
    private var pumpLevels: [String: Double] {
        guard let profile = profiles.first else { return [:] }
        return Dictionary(uniqueKeysWithValues: WorkoutPlan.allMuscleGroups.map {
            ($0, profile.effectivePumpLevel(for: $0))
        })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        VStack(spacing: 6) {
                            Text("\(completedEntries.count) workouts completed")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)

                            Text(
                                "\(totalWeeklySets) real sets • \(formatVolume(totalWeeklyVolume)) kg volume this week"
                            )
                            .font(.caption)
                            .foregroundStyle(.orange)
                        }
                        .padding(.top, 16)

                        VStack(spacing: 14) {
                            Picker("", selection: $showFront) {
                                Text("Front view").tag(true)
                                Text("Back View").tag(false)
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 200)

                            BodyFigureView(
                                pumpLevels: pumpLevels,   // ← era weeklySets: weeklySets
                                showFront: showFront
                            )
                            .frame(maxWidth: 220)

                            HStack(spacing: 16) {
                                legendDot(
                                    color: Color(
                                        red: 0x35 / 255,
                                        green: 0x2D / 255,
                                        blue: 0x27 / 255
                                    ),
                                    label: "a bit"
                                )

                                legendDot(
                                    color: Color(
                                        red: 1,
                                        green: 138.0 / 255,
                                        blue: 92.0 / 255
                                    ),
                                    label: "good"
                                )

                                legendDot(
                                    color: Color(
                                        red: 1,
                                        green: 106.0 / 255,
                                        blue: 52.0 / 255
                                    ),
                                    label: "perfect"
                                )
                            }
                            .font(.caption2)
                            .foregroundStyle(Theme.textSecondary)
                        }
                        .glassCard()

                        VStack(spacing: 10) {
                            ForEach(
                                WorkoutPlan.allMuscleGroups,
                                id: \.self
                            ) { muscle in

                                let sets = Int(weeklySets[muscle] ?? 0)
                                let volume = weeklyVolume[muscle] ?? 0

                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(muscle)
                                            .font(.subheadline)
                                            .foregroundStyle(Theme.textPrimary)

                                        Text("\(sets) real sets")
                                            .font(.caption)
                                            .foregroundStyle(Theme.textSecondary)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 3) {
                                        if volume > 0 {
                                            Text("\(formatVolume(volume)) kg")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.orange)
                                        } else {
                                            Text("Bodyweight")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(Theme.textSecondary)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .glassCard(padding: 0)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                    .background {
//                        RenderMotionProbe(name: "Training tab scroll content")
//                            .frame(width: 1, height: 1)
//                            .allowsHitTesting(false)
                   }
                }
                .transaction {
                    $0.scrollContentOffsetAdjustmentBehavior = .disabled
                }
            }
            .navigationTitle("Training")
            .fontDesign(.rounded)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 11, height: 11)

            Text(label)
        }
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume.rounded() == volume {
            return "\(Int(volume))"
        }

        return String(format: "%.1f", volume)
    }
}
