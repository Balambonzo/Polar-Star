import SwiftUI
import SwiftData

struct TrainingView: View {
    @Query private var trainingEntries: [TrainingEntry]
    @State private var appeared = false
    @State private var showFront = true

    private var weeklySets: [String: Double] {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let daysSinceMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: calendar.startOfDay(for: now)) else { return [:] }

        var counts: [String: Int] = [:]
        for entry in trainingEntries where entry.date >= monday {
            for muscle in entry.muscleGroups {
                counts[muscle, default: 0] += 1
            }
        }
        // Stima: ~3 serie per esercizio a sessione (non logghiamo ancora
        // le serie una per una — è la Fase 3, non ancora costruita).
        return counts.mapValues { Double($0) * 3.0 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()
                ScrollView {
                    VStack(spacing: 18) {
                        Text("\(trainingEntries.count) workouts completed")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.top, 16)

                        VStack(spacing: 14) {
                            Picker("", selection: $showFront) {
                                Text("Front view").tag(true)
                                Text("Back View").tag(false)
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 200)

                            BodyFigureView(weeklySets: weeklySets, showFront: showFront)
                                .frame(maxWidth: 220)

                            HStack(spacing: 16) {
                                legendDot(color: Color(red: 0x35 / 255, green: 0x2D / 255, blue: 0x27 / 255), label: "a bit")
                                legendDot(color: Color(red: 1, green: 138.0 / 255, blue: 92.0 / 255), label: "good")
                                legendDot(color: Color(red: 1, green: 106.0 / 255, blue: 52.0 / 255), label: "perfect")
                            }
                            .font(.caption2)
                            .foregroundStyle(Theme.textSecondary)
                        }
                        .glassCard()

                        VStack(spacing: 10) {
                            ForEach(WorkoutPlan.allMuscleGroups, id: \.self) { muscle in
                                HStack {
                                    Text(muscle)
                                        .font(.subheadline)
                                        .foregroundStyle(Theme.textPrimary)
                                    Spacer()
                                    Text("\(Int(weeklySets[muscle] ?? 0)) set this week")
                                        .font(.caption)
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .glassCard(padding: 0)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Training")
            .fontDesign(.rounded)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) { appeared = true }
            }
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
}
