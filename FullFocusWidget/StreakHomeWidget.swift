import WidgetKit
import SwiftUI

struct StreakHomeWidgetView: View {
    var entry: StreakEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill").foregroundStyle(.orange)
                Text("\(entry.currentStreak) \(entry.currentStreak == 1 ? "giorno" : "giorni")")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
            }
            Text(entry.motivationalLine)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(3)
            Spacer(minLength: 0)
            if !entry.todayDone {
                Text("Not done yet for today")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

struct StreakHomeWidget: Widget {
    let kind = "StreakHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakTimelineProvider()) { entry in
            StreakHomeWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(colors: [.black, .orange.opacity(0.25)],
                                    startPoint: .top, endPoint: .bottom)
                }
        }
        .configurationDisplayName("Streak")
        .description("It shows the current streak and a motivational line")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
