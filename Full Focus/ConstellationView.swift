import SwiftUI
import SwiftData

struct ConstellationView: View {
    @Query(sort: \StudyEntry.date) private var entries: [StudyEntry]
    @Query private var profiles: [UserProfile]
    @Query private var trainingEntries: [TrainingEntry]
    @Query private var readingSessions: [ReadingSession]
    @Query private var customEntries: [CustomActivityEntry]

    @State private var selectedDetail: DayDetail?
    @State private var appeared = false
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    struct DayDetail: Identifiable {
        let date: Date
        let totalMinutes: Int
        let photoFileName: String?
        let milestone: StarType?
        let completedActivityLabels: [String]
        var id: Date { date }
    }

    private var selectedActivities: [String] {
        profiles.first?.selectedActivities ?? []
    }

    private var aggregation: ActivityAggregator.Result {
        ActivityAggregator.aggregate(
            selectedActivities: selectedActivities,
            studyEntries: entries,
            trainingEntries: trainingEntries,
            readingSessions: readingSessions,
            customEntries: customEntries
        )
    }

    private var days: [DayInfo] {
        StreakCalculator.gridDays(
            completedDates: aggregation.completedDates,
            dayRecords: aggregation.dayRecords,
            firstDate: aggregation.firstDate
        )
    }

    private var stats: StreakStats {
        StreakCalculator.stats(completedDates: aggregation.completedDates)
    }

    private var streakPositions: [Date: Int] {
        StreakCalculator.streakPositions(for: days)
    }

    private var layout: ConstellationLayoutResult {
        ConstellationLayout.compute(days: days)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    StarfieldBackground()

                    if layout.stars.isEmpty {
                        ContentUnavailableView(
                            "The sky is still empty!",
                            systemImage: "sparkles",
                            description: Text("A complete day ligths up a star, and a streak of days lights up a constellation. Keep going!")
                        )
                    } else {
                        ZStack {
                            connectionsCanvas
                            ForEach(Array(layout.stars.enumerated()), id: \.element.id) { index, star in
                                starNode(star, index: index)
                                    .position(x: star.x, y: star.y)
                                    .opacity(appeared ? 1 : 0)
                                    .scaleEffect(appeared ? 1 : 0.3)
                            }
                        }
                        .frame(width: layout.contentSize.width, height: layout.contentSize.height)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = min(max(lastScale * value, 0.5), 3)
                                    }
                                    .onEnded { _ in lastScale = scale },
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in lastOffset = offset }
                            )
                        )
                    }

                    header

                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                Haptics.tap()
                                centerOnLatest(containerSize: geo.size)
                            } label: {
                                Image(systemName: "scope")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .padding(14)
                                    .background(Theme.card, in: Circle())
                                    .overlay(Circle().stroke(Theme.cardBorder, lineWidth: 1))
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 30)
                        }
                    }
                }
                .onAppear {
                    withAnimation(.easeOut(duration: 0.6)) { appeared = true }
                    centerOnLatest(containerSize: geo.size, animated: false)
                }
            }
            .navigationTitle("Constellations")
            .fontDesign(.rounded)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(item: $selectedDetail) { detail in
                DayDetailView(detail: detail)
            }
        }
    }

    private var header: some View {
        VStack {
            VStack(spacing: 2) {
                Text("\(stats.currentStreak) \(stats.currentStreak == 1 ? "day" : "days") in a row")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text("\(aggregation.completedDates.count) stars lighted up · record \(stats.bestStreak)")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 18)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.top, 8)
            Spacer()
        }
    }

    private var connectionsCanvas: some View {
        Canvas { context, _ in
            for (a, b) in layout.connections {
                guard a < layout.stars.count, b < layout.stars.count else { continue }
                var path = Path()
                path.move(to: CGPoint(x: layout.stars[a].x, y: layout.stars[a].y))
                path.addLine(to: CGPoint(x: layout.stars[b].x, y: layout.stars[b].y))
                context.stroke(path, with: .color(Color.orange.opacity(0.3)), lineWidth: 1.2)
            }
        }
        .frame(width: layout.contentSize.width, height: layout.contentSize.height)
    }

    @ViewBuilder
    private func starNode(_ star: StarPosition, index: Int) -> some View {
        let isLatest = index == layout.latestStarIndex
        switch star.day.status {
        case .completed(let record):
            let starType: StarType = {
                if let position = streakPositions[star.day.date],
                   let milestone = StarType.milestone(forStreakPosition: position) {
                    return milestone
                }
                return StarType.forDuration(minutes: record.totalMinutes)
            }()
            ConstellationStar(record: record, starType: starType, isLatest: isLatest)
                .onTapGesture {
                    Haptics.tap()
                    selectedDetail = buildDetail(for: star.day)
                }
        case .todayPending:
            PendingConstellationStar()
        case .missed:
            EmptyView()
        }
    }

    private func buildDetail(for day: DayInfo) -> DayDetail {
        let calendar = Calendar.current
        var labels: [String] = []
        if entries.contains(where: { calendar.isDate($0.date, inSameDayAs: day.date) }) { labels.append("Study ") }
        if trainingEntries.contains(where: { calendar.isDate($0.date, inSameDayAs: day.date) }) { labels.append("Training") }
        if readingSessions.contains(where: { calendar.isDate($0.date, inSameDayAs: day.date) }) { labels.append("Reading") }
        if customEntries.contains(where: { calendar.isDate($0.date, inSameDayAs: day.date) }) { labels.append(profiles.first?.customActivityName ?? "Other") }

        var totalMinutes = 0
        var photo: String? = nil
        if case .completed(let record) = day.status {
            totalMinutes = record.totalMinutes
            photo = record.photoFileName
        }
        let milestone = streakPositions[day.date].flatMap { StarType.milestone(forStreakPosition: $0) }

        return DayDetail(date: day.date, totalMinutes: totalMinutes, photoFileName: photo, milestone: milestone, completedActivityLabels: labels)
    }

    private func centerOnLatest(containerSize: CGSize, animated: Bool = true) {
        guard let idx = layout.latestStarIndex, idx < layout.stars.count else { return }
        let star = layout.stars[idx]
        let target = CGSize(width: containerSize.width / 2 - star.x, height: containerSize.height / 2 - star.y)
        if animated {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                scale = 1; lastScale = 1
                offset = target; lastOffset = target
            }
        } else {
            scale = 1; lastScale = 1
            offset = target; lastOffset = target
        }
    }
}

private struct ConstellationStar: View {
    let record: DayRecord
    let starType: StarType
    let isLatest: Bool
    @State private var glow = false

    private var size: CGFloat { starType.baseSize + (isLatest ? 6 : 0) }
    private var photoSize: CGFloat { size - 12 }

    var body: some View {
        ZStack {
            if starType == .blackHole {
                Circle()
                    .stroke(starType.glowColor.opacity(glow ? 0.9 : 0.5), lineWidth: 3)
                    .frame(width: size, height: size)
                    .blur(radius: 3)
                Circle()
                    .fill(Color.black)
                    .frame(width: size - 8, height: size - 8)
            } else {
                Circle()
                    .fill(starType.glowColor.opacity(glow ? 0.5 : 0.28))
                    .frame(width: size, height: size)
                    .blur(radius: 8)
            }

            if let photoFileName = record.photoFileName, let uiImage = ImageStore.load(photoFileName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: photoSize, height: photoSize)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(
                            LinearGradient(colors: [starType.coreColor, starType.coreColor.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: isLatest ? 2.5 : 1.5
                        )
                    )
            } else {
                Circle()
                    .fill(starType.coreColor)
                    .frame(width: photoSize * 0.5, height: photoSize * 0.5)
            }
        }
        .shadow(color: starType.glowColor.opacity(0.5), radius: isLatest ? 10 : 5)
        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: glow)
        .onAppear {
            glow = true
        }
    }
}


private struct PendingConstellationStar: View {
    @State private var pulse = false

    var body: some View {
        Circle()
            .stroke(Color.orange.opacity(0.6), lineWidth: 2)
            .frame(width: 30, height: 30)
            .scaleEffect(pulse ? 1.25 : 1.0)
            .opacity(pulse ? 0 : 1)
            .overlay(Circle().fill(Color.orange.opacity(0.15)).frame(width: 30, height: 30))
            .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: pulse)
            .onAppear {
                pulse = true
            }
    }
}

