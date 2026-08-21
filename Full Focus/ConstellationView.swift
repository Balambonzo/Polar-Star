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

    // Layout "pesante" cachato in @State: si ricalcola solo quando cambiano
    // davvero i dati (vedi `.task(id: dataFingerprint)`), non ad ogni
    // ridisegno della vista (scroll, apertura sheet, ecc.).
    @State private var galaxies: [GalaxyGroup] = []
    @State private var streakPositions: [Date: Int] = [:]
    @State private var stats = StreakCalculator.stats(completedDates: [])
    @State private var completedStarCount = 0
    @State private var latestDate: Date?
    @State private var didInitialScroll = false

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

    /// Impronta "leggera" dei dati da cui dipende il layout: quando cambia,
    /// e solo allora, ricostruiamo galassie/costellazioni/streak.
    private var dataFingerprint: String {
        [
            "e\(entries.count)",
            "t\(trainingEntries.count)",
            "r\(readingSessions.count)",
            "c\(customEntries.count)",
            selectedActivities.joined(separator: ","),
            profiles.first?.customActivityName ?? ""
        ].joined(separator: "|")
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ZStack {
                    StarfieldBackground()

                    if galaxies.isEmpty {
                        ContentUnavailableView(
                            "The sky is still empty!",
                            systemImage: "sparkles",
                            description: Text("A complete day ligths up a star, and a streak of days lights up a constellation. Keep going!")
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 20) {
                                ForEach(galaxies) { galaxy in
                                    if galaxy.extraGapBefore > 0 {
                                        Color.clear.frame(height: galaxy.extraGapBefore)
                                    }
                                    GalaxyFlowView(
                                        galaxy: galaxy,
                                        streakPositions: streakPositions,
                                        latestDate: latestDate
                                    ) { day in
                                        Haptics.tap()
                                        selectedDetail = buildDetail(for: day)
                                    }
                                    .id(galaxy.id)
                                }
                            }
                            .padding(.top, 104)
                            .padding(.bottom, 80)
                        }
                        .opacity(appeared ? 1 : 0)
                    }

                    header

                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                Haptics.tap()
                                scrollToLatest(proxy: proxy, animated: true)
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
                .task(id: dataFingerprint) {
                    recomputeLayout()
                    withAnimation(.easeOut(duration: 0.5)) { appeared = true }
                    // Piccolo respiro perché la ScrollView monti le nuove celle
                    // prima di chiederle di scorrere fino in fondo.
                    try? await Task.sleep(nanoseconds: 60_000_000)
                    scrollToLatest(proxy: proxy, animated: didInitialScroll)
                    didInitialScroll = true
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
                Text("\(completedStarCount) stars lighted up · record \(stats.bestStreak)")
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

    private func scrollToLatest(proxy: ScrollViewProxy, animated: Bool) {
        guard let lastID = galaxies.last?.id else { return }
        if animated {
            withAnimation(.easeOut(duration: 0.5)) {
                proxy.scrollTo(lastID, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(lastID, anchor: .bottom)
        }
    }

    private func recomputeLayout() {
        let aggregation = ActivityAggregator.aggregate(
            selectedActivities: selectedActivities,
            studyEntries: entries,
            trainingEntries: trainingEntries,
            readingSessions: readingSessions,
            customEntries: customEntries
        )
        let days = StreakCalculator.gridDays(
            completedDates: aggregation.completedDates,
            dayRecords: aggregation.dayRecords,
            firstDate: aggregation.firstDate
        )

        galaxies = ConstellationLayout.buildGalaxies(from: days)
        streakPositions = StreakCalculator.streakPositions(for: days)
        stats = StreakCalculator.stats(completedDates: aggregation.completedDates)
        completedStarCount = aggregation.completedDates.count
        latestDate = days.last(where: {
            switch $0.status {
            case .completed, .todayPending: return true
            case .missed: return false
            }
        })?.date
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
}

// MARK: - Galassia: nessun contenitore visivo, solo filo + stelle

private struct GalaxyFlowView: View {
    let galaxy: GalaxyGroup
    let streakPositions: [Date: Int]
    let latestDate: Date?
    let onTapStar: (DayInfo) -> Void

    var body: some View {
        ZStack {
            Canvas { context, _ in
                var path = Path()
                for (a, b) in galaxy.connections {
                    guard a < galaxy.stars.count, b < galaxy.stars.count else { continue }
                    path.move(to: CGPoint(x: galaxy.stars[a].x, y: galaxy.stars[a].y))
                    path.addLine(to: CGPoint(x: galaxy.stars[b].x, y: galaxy.stars[b].y))
                }
                context.stroke(
                    path,
                    with: .color(.orange.opacity(0.3)),
                    style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round)
                )
            }
            .frame(width: galaxy.size.width, height: galaxy.size.height)

            ForEach(galaxy.stars) { star in
                starView(for: star.day)
                    .position(x: star.x, y: star.y)
            }
        }
        .frame(width: galaxy.size.width, height: galaxy.size.height)
    }

    @ViewBuilder
    private func starView(for day: DayInfo) -> some View {
        switch day.status {
        case .completed(let record):
            let starType: StarType = {
                if let position = streakPositions[day.date],
                   let milestone = StarType.milestone(forStreakPosition: position) {
                    return milestone
                }
                return StarType.forDuration(minutes: record.totalMinutes)
            }()
            ConstellationStarNode(record: record, starType: starType, isLatest: day.date == latestDate)
                .onTapGesture {
                    onTapStar(day)
                }
        case .todayPending:
            PendingConstellationStar()
        case .missed:
            EmptyView()
        }
    }
}

// MARK: - Singola stella

private struct ConstellationStarNode: View {
    let record: DayRecord
    let starType: StarType
    let isLatest: Bool
    @State private var glow = false

    // Ottimizzazione chiave: l'animazione infinita (repeatForever) gira solo
    // per l'ultima stella e per le stelle speciali, mai per centinaia di
    // stelle ordinarie contemporaneamente.
    private var shouldAnimate: Bool { isLatest || starType.isSpecial }
    private var size: CGFloat { starType.baseSize + (isLatest ? 6 : 0) }
    private var photoSize: CGFloat { size - 12 }

    var body: some View {
        ZStack {
            // Alone morbido via gradiente radiale: stesso effetto visivo di
            // un .blur(), ma senza il costo del filtro Gaussiano per stella.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [starType.glowColor.opacity(glow ? 0.55 : 0.3), starType.glowColor.opacity(0)],
                        center: .center, startRadius: 0, endRadius: size * 0.62
                    )
                )
                .frame(width: size * 1.3, height: size * 1.3)

            if starType.isSpecial {
                SpecialStarShapeView(type: starType, size: size, animate: shouldAnimate)
            }

            if let photoFileName = record.photoFileName, let uiImage = ImageCache.shared.image(named: photoFileName) {
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
            } else if !starType.isSpecial {
                Circle()
                    .fill(starType.coreColor)
                    .frame(width: photoSize * 0.5, height: photoSize * 0.5)
            }

            if isLatest {
                Circle()
                    .stroke(Color.white.opacity(0.8), lineWidth: 1.4)
                    .frame(width: size + 10, height: size + 10)
            }
        }
        .shadow(color: starType.glowColor.opacity(shouldAnimate ? 0.45 : 0.2), radius: isLatest ? 8 : 3)
        .contentShape(Circle().inset(by: -10)) // area di tocco comoda anche per le stelle piccole
        .animation(shouldAnimate ? .easeInOut(duration: 1.6).repeatForever(autoreverses: true) : nil, value: glow)
        .onAppear {
            if shouldAnimate { glow = true }
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
