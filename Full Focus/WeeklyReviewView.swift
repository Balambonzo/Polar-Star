import SwiftUI
import SwiftData

struct WeeklyReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    @Query(sort: \StudyEntry.date) private var entries: [StudyEntry]
    @Query private var trainingEntries: [TrainingEntry]
    @Query private var readingSessions: [ReadingSession]
    @Query private var customEntries: [CustomActivityEntry]

    @State private var appeared = false

    private var review: WeeklyReviewData {
        WeeklyReviewCalculator.compute(
            selectedActivities: profiles.first?.selectedActivities ?? [],
            customActivityName: profiles.first?.customActivityName,
            studyEntries: entries,
            trainingEntries: trainingEntries,
            readingSessions: readingSessions,
            customEntries: customEntries
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        header
                        dayDotsRow
                        perfectDaysHero
                        statsGrid
                        comparisonCard
                        suggestionCard
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Your week")
            .navigationBarTitleDisplayMode(.inline)
            .fontDesign(.rounded)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .tint(.orange)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) { appeared = true }
            }
        }
    }

    // MARK: - Intestazione

    private var header: some View {
        VStack(spacing: 4) {
            Text(dateRangeText)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
        .opacity(appeared ? 1 : 0)
    }

    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return "\(formatter.string(from: review.weekStart)) – \(formatter.string(from: review.weekEnd))"
    }

    // MARK: - Puntini dei giorni

    private var dayDotsRow: some View {
        let labels = ["L", "M", "M", "G", "V", "S", "D"]
        return HStack(spacing: 10) {
            ForEach(0..<7, id: \.self) { i in
                VStack(spacing: 6) {
                    dayDot(for: review.dayStates[i])
                    Text(labels[i])
                        .font(.caption2)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
        }
        .opacity(appeared ? 1 : 0)
    }

    @ViewBuilder
    private func dayDot(for state: DayReviewState) -> some View {
        switch state {
        case .perfect:
            Circle()
                .fill(Color.orange)
                .frame(width: 14, height: 14)
                .shadow(color: .orange.opacity(0.6), radius: 5)
        case .incomplete:
            Circle()
                .stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 1.5, dash: [2, 3]))
                .frame(width: 14, height: 14)
        case .todayPending:
            Circle()
                .stroke(Color.orange.opacity(0.7), lineWidth: 2)
                .frame(width: 14, height: 14)
        case .future:
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 14, height: 14)
        }
    }

    // MARK: - Perfect days, in grande

    private var perfectDaysHero: some View {
        VStack(spacing: 8) {
            Text("\(review.perfectDays)")
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text("perfect days on \(review.daysElapsed)")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .glassCard(padding: 0)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
    }

    // MARK: - Griglia statistiche

    private var statsGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
        return LazyVGrid(columns: columns, spacing: 12) {
            statTile(icon: "checkmark.circle.fill", value: "\(review.activitiesCompleted)", label: "Completed activities")
            statTile(icon: "clock.fill", value: minutesLabel(review.totalMinutes), label: "Total time")
            statTile(icon: "book.fill", value: minutesLabel(review.studyMinutes), label: "Study")
            statTile(icon: "figure.strengthtraining.traditional", value: "\(review.trainingSessions)", label: "Training sessions")
            statTile(icon: "book.closed.fill", value: minutesLabel(review.readingMinutes), label: "Reading")
            statTile(icon: "flame.fill", value: "\(review.currentStreak)", label: "Current streak")
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
    }

    private func minutesLabel(_ minutes: Int) -> String {
        minutes >= 60 ? String(format: "%.1f h", Double(minutes) / 60.0) : "\(minutes) min"
    }

    private func statTile(icon: String, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundStyle(.orange).font(.subheadline)
            Text(value).font(.title3.bold()).foregroundStyle(Theme.textPrimary)
            Text(label).font(.caption2).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    // MARK: - Confronto con la settimana scorsa

    private var comparisonCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Compared to the last week")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                trendBadge
            }

            comparisonRow(label: "Perfect days", current: review.perfectDays, previous: review.previousWeek.perfectDays)
            comparisonRow(label: "Completed activities", current: review.activitiesCompleted, previous: review.previousWeek.activitiesCompleted)
            comparisonRow(label: "Total minutes", current: review.totalMinutes, previous: review.previousWeek.totalMinutes)
        }
        .glassCard()
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
    }

    private var trendBadge: some View {
        let (icon, color, text): (String, Color, String) = {
            switch review.trend {
            case .up: return ("arrow.up.right", .green, "Growing up")
            case .down: return ("arrow.down.right", .orange, "Going down")
            case .steady: return ("arrow.right", Theme.textSecondary, "Stable")
            }
        }()
        return Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15), in: Capsule())
    }

    private func comparisonRow(label: String, current: Int, previous: Int) -> some View {
        HStack {
            Text(label)
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text("\(previous)")
                .font(.footnote)
                .foregroundStyle(Theme.textTertiary)
            Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundStyle(Theme.textTertiary)
            Text("\(current)")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
        }
    }

    // MARK: - Suggerimento

    private var suggestionCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.orange)
                .font(.title3)
            Text(review.suggestion)
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
    }
}
