import SwiftUI
import SwiftData
import UIKit
import WidgetKit

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StudyEntry.date) private var entries: [StudyEntry]
    @Query private var profiles: [UserProfile]
    @Query private var trainingEntries: [TrainingEntry]
    @Query private var readingSessions: [ReadingSession]
    @Query private var customEntries: [CustomActivityEntry]

    @State private var showCamera = false
    @State private var showSecondCamera = false
    @State private var showISBNScanner = false
    @State private var showReadingSetup = false
    @State private var showTrainingSetup = false
    @State private var appeared = false
    @State private var celebratingMilestone: (StarType, Int)?

    @State private var studyTimer = StudyTimerController(id: "study")
    @State private var trainingTimer = StudyTimerController(id: "training")
    @State private var readingTimer = StudyTimerController(id: "reading")
    @State private var customTimer = StudyTimerController(id: "custom")

    @State private var selectedDurationMinutes = 15
    @State private var pageReachedText = ""
    @State private var selectedBookForSession: Book?
    @State private var selectedTrainingMuscles: Set<String> = []

    @State private var activeFlow: ActiveFlow?
    @Environment(\.scenePhase) private var scenePhase

    private enum ActiveFlow { case study, training, reading, custom }
    private let canonicalOrder = [ActivityKey.study.rawValue, ActivityKey.training.rawValue, ActivityKey.reading.rawValue, ActivityKey.custom.rawValue]

    private var selectedActivities: [String] {
        profiles.first?.selectedActivities ?? []
    }

    private var studyDoneRaw: Bool {
        entries.contains { Calendar.current.isDateInToday($0.date) }
    }

    private func isDoneToday(_ key: String) -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        switch key {
        case ActivityKey.study.rawValue: return studyDoneRaw
        case ActivityKey.training.rawValue: return trainingEntries.contains { Calendar.current.startOfDay(for: $0.date) == today }
        case ActivityKey.reading.rawValue: return readingSessions.contains { Calendar.current.startOfDay(for: $0.date) == today }
        case ActivityKey.custom.rawValue: return customEntries.contains { Calendar.current.startOfDay(for: $0.date) == today }
        default: return false
        }
    }

    private var pendingActivities: [String] {
        canonicalOrder.filter { selectedActivities.contains($0) && !isDoneToday($0) }
    }

    private var todayProgressFraction: Double {
        guard !selectedActivities.isEmpty else { return 0 }
        let doneCount = selectedActivities.filter { isDoneToday($0) }.count
        return Double(doneCount) / Double(selectedActivities.count)
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

    private var stats: StreakStats {
        StreakCalculator.stats(completedDates: aggregation.completedDates)
    }

    private var currentTrainingLevel: TrainingLevel {
        TrainingLevel(rawValue: profiles.first?.trainingLevel ?? "") ?? .beginner
    }

    var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()

                VStack(spacing: 28) {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Theme.accent.opacity(0.08))
                            .frame(width: 250, height: 250)
                            .blur(radius: 20)

                        Circle()
                            .stroke(Theme.cardBorder, lineWidth: 14)
                            .frame(width: 224, height: 224)

                        Circle()
                            .trim(from: 0, to: max(todayProgressFraction, 0.001))
                            .stroke(
                                AngularGradient(
                                    colors: todayProgressFraction >= 1
                                        ? [.green, .mint, .green]
                                        : [.orange, .yellow, .orange],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 14, lineCap: .round)
                            )
                            .frame(width: 224, height: 224)
                            .rotationEffect(.degrees(-90))
                            .glow(todayProgressFraction >= 1 ? .green : .orange, radius: 10)

                        VStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(todayProgressFraction >= 1 ? .green : .orange)
                            Text("\(stats.currentStreak)")
                                .font(.system(size: 68, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                                .monospacedDigit()
                                .contentTransition(.numericText())
                            Text(stats.currentStreak == 1 ? "day" : "days")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: stats.currentStreak)
                    .scaleEffect(appeared ? 1 : 0.85)
                    .opacity(appeared ? 1 : 0)
                    .overlay {
                        if let (starType, days) = celebratingMilestone {
                            MilestoneCelebrationView(starType: starType, streakDays: days)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                                        withAnimation { celebratingMilestone = nil }
                                    }
                                }
                                .transition(.opacity)
                        }
                    }

                    VStack(spacing: 8) {
                        Text(stats.todayDone ? "This is the way" : "Not finished yet")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                        Text("Record: \(stats.bestStreak) \(stats.bestStreak == 1 ? "day" : "days")")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .opacity(appeared ? 1 : 0)

                    Spacer()

                    Group {
                        if stats.todayDone {
                            Label("Done for today", systemImage: "checkmark.seal.fill")
                                .font(.headline)
                                .foregroundStyle(.green)
                                .frame(maxWidth: .infinity)
                                .glassCard()
                        } else if activeFlow == .study {
                            studyFlowCard
                        } else if activeFlow == .training {
                            trainingFlowCard
                        } else if activeFlow == .reading {
                            readingFlowCard
                        } else if activeFlow == .custom {
                            customFlowCard
                        } else {
                            activityChoiceGrid
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 20)
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle("Today")
            .fontDesign(.rounded)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                    appeared = true
                }
                studyTimer.handleScenePhase(scenePhase)
                trainingTimer.handleScenePhase(scenePhase)
                readingTimer.handleScenePhase(scenePhase)
                customTimer.handleScenePhase(scenePhase)
            }
            .onChange(of: scenePhase) { _, newPhase in
                studyTimer.handleScenePhase(newPhase)
                trainingTimer.handleScenePhase(newPhase)
                readingTimer.handleScenePhase(newPhase)
                customTimer.handleScenePhase(newPhase)
            }
            .sheet(isPresented: $showCamera) {
                CameraCaptureView { image in save(image) }
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showSecondCamera) {
                CameraCaptureView { image in saveCustomActivity(image) }
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showISBNScanner) {
                ISBNScannerFlow { book in
                    modelContext.insert(book)
                    try? modelContext.save()
                    showISBNScanner = false
                    showReadingSetup = true
                }
            }
            .sheet(isPresented: $showReadingSetup) {
                ReadingSessionSetupView(
                    onStart: { book, minutes in
                                            selectedBookForSession = book
                                            readingTimer.start(minutes: minutes)
                                            showReadingSetup = false
                                        },
                    onNewBook: {
                        showReadingSetup = false
                        showISBNScanner = true
                    }
                )
            }
            .sheet(isPresented: $showTrainingSetup) {
                if let profile = profiles.first {
                    TrainingSessionSetupView(profile: profile, level: currentTrainingLevel, minimumMinutes: currentTrainingLevel.minimumSessionMinutes) { muscles, minutes in
                        selectedTrainingMuscles = muscles
                        trainingTimer.start(minutes: minutes)
                        showTrainingSetup = false
                    }
                }
            }
        }
    }

    // MARK: - Scelta attività

    private var activityChoiceGrid: some View {
        VStack(spacing: 12) {
            ForEach(rowsForChoiceGrid(), id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            Haptics.selection()
                            select(key)
                        } label: {
                            activityChoiceLabel(icon: icon(for: key), title: title(for: key))
                        }
                    }
                }
            }
        }
    }

    private func select(_ key: String) {
        switch key {
        case ActivityKey.study.rawValue:
            activeFlow = .study
        case ActivityKey.training.rawValue:
            activeFlow = .training
            showTrainingSetup = true
        case ActivityKey.reading.rawValue:
            activeFlow = .reading
            showReadingSetup = true
        default:
            activeFlow = .custom
        }
    }

    private func rowsForChoiceGrid() -> [[String]] {
        let items = pendingActivities
        guard !items.isEmpty else { return [] }
        if items.count == 3 {
            return [[items[0], items[1]], [items[2]]]
        }
        var rows: [[String]] = []
        var i = 0
        while i < items.count {
            let end = min(i + 2, items.count)
            rows.append(Array(items[i..<end]))
            i = end
        }
        return rows
    }

    private func icon(for key: String) -> String {
        switch key {
        case ActivityKey.study.rawValue: return "book.fill"
        case ActivityKey.training.rawValue: return "figure.strengthtraining.traditional"
        case ActivityKey.reading.rawValue: return "book.closed.fill"
        default: return "star.fill"
        }
    }

    private func title(for key: String) -> String {
        switch key {
        case ActivityKey.study.rawValue: return "Study"
        case ActivityKey.training.rawValue: return "Training"
        case ActivityKey.reading.rawValue: return "Reading"
        default: return profiles.first?.customActivityName ?? "Other"
        }
    }

    private func activityChoiceLabel(icon: String, title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2)
            Text(title).font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .foregroundStyle(.white)
        .background(Color.orange, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .orange.opacity(0.3), radius: 10, y: 5)
    }

    private var backButton: some View {
        Button {
            Haptics.tap()
            activeFlow = nil
        } label: {
            Label("Back", systemImage: "chevron.left")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Theme.card, in: Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func durationLabel(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) min" }
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)min"
    }

    private func timeLabel(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }

    /// Coppia Pausa/Riprendi + Annulla, condivisa dai quattro timer.
    private func pauseCancelRow(for timer: StudyTimerController) -> some View {
            HStack(spacing: 10) {
                Button {
                    Haptics.tap()
                    if timer.isPaused {
                        timer.resume()
                    } else {
                        timer.pause()
                    }
                } label: {
                    Text(timer.isPaused ? "Play" : "Stop")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                }
                Button {
                    Haptics.tap()
                    timer.cancel()
                } label: {
                    Text("Exit")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.top, 8)
        }

    // MARK: - Studio

    private var studyFlowCard: some View {
        VStack(spacing: 12) {
            if studyTimer.isCompleted {
                Button {
                    Haptics.action()
                    showCamera = true
                } label: {
                    Label("Take today's picture!", systemImage: "camera.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundStyle(.white)
                        .background(Color.orange, in: RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .orange.opacity(0.35), radius: 14, y: 6)
                }
            } else if studyTimer.isActive {
                VStack(spacing: 12) {
                    Text(timeLabel(studyTimer.remainingSeconds))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .monospacedDigit()
                    ProgressView(value: studyTimer.progress).tint(.orange)
                    Text("Don't open any other apps or the timer will stop!")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                    pauseCancelRow(for: studyTimer)
                }
                .glassCard()
            } else {
                backButton
                VStack(spacing: 16) {
                    Text("How much today boss?")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                    Picker("Last", selection: $selectedDurationMinutes) {
                        ForEach(Array(stride(from: 15, through: 180, by: 15)), id: \.self) { minutes in
                            Text(durationLabel(minutes)).tag(minutes)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                    Button {
                        Haptics.action()
                        studyTimer.start(minutes: selectedDurationMinutes)
                        } label: {
                        Label("Let's start", systemImage: "timer")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundStyle(.white)
                            .background(Color.orange, in: RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .orange.opacity(0.35), radius: 14, y: 6)
                    }
                }
                .glassCard()
            }
        }
    }

    private func save(_ image: UIImage) {
        guard let fileName = ImageStore.save(image) else { return }
        let durationMinutes = Int(studyTimer.totalDuration / 60)
        let entry = StudyEntry(date: Date(), imageFileName: fileName, studyDurationMinutes: durationMinutes)
        modelContext.insert(entry)
        try? modelContext.save()

        Haptics.success()
        refreshExternalState(newStudyEntry: entry, freshPhoto: image)

        studyTimer.markConsumed()
        activeFlow = nil
    }

    // MARK: - Allenamento

    private var trainingFlowCard: some View {
        VStack(spacing: 12) {
            if trainingTimer.isActive && !trainingTimer.isCompleted {
                VStack(spacing: 12) {
                    Text(timeLabel(trainingTimer.remainingSeconds))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .monospacedDigit()
                    ProgressView(value: trainingTimer.progress).tint(.orange)
                    Text(selectedTrainingMuscles.sorted().joined(separator: ", "))
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                    pauseCancelRow(for: trainingTimer)
                }
                .glassCard()
            } else {
                backButton
            }
        }
        .onChange(of: trainingTimer.isCompleted) { _, completed in
            if completed { completeTraining() }
        }
    }

    private func completeTraining() {
        let minutes = Int(trainingTimer.totalDuration / 60)
        let entry = TrainingEntry(date: Date(), muscleGroups: Array(selectedTrainingMuscles), level: currentTrainingLevel, durationMinutes: minutes)
        modelContext.insert(entry)
        advanceTrainingProgress(for: Array(selectedTrainingMuscles))
        try? modelContext.save()
        Haptics.success()
        refreshExternalState()
        trainingTimer.markConsumed()
        activeFlow = nil
    }

    private func advanceTrainingProgress(for muscles: [String]) {
        guard let profile = profiles.first else { return }
        var progress = profile.trainingProgress
        for muscle in muscles {
            var mp = progress[muscle] ?? UserProfile.MuscleProgress(chainIndex: currentTrainingLevel.startingChainOffset, sessionsAtLevel: 0)
            mp.sessionsAtLevel += 1
            if mp.sessionsAtLevel >= 4 {
                let maxIndex = WorkoutPlan.chainLength(for: muscle) - 1
                if mp.chainIndex < maxIndex {
                    mp.chainIndex += 1
                }
                mp.sessionsAtLevel = 0
            }
            progress[muscle] = mp
        }
        profile.trainingProgress = progress
    }

    // MARK: - Lettura

    private var readingFlowCard: some View {
        Group {
            if readingTimer.isCompleted {
                VStack(spacing: 14) {
                    Text("What page did you reach today?")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    TextField("Page", text: $pageReachedText)
                        .keyboardType(.numberPad)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.textPrimary)
                        .padding()
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                    Button {
                        Haptics.action()
                        saveReadingSession()
                    } label: {
                        Text("Save Progress")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundStyle(.white)
                            .background(Color.orange, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(Int(pageReachedText) == nil)
                }
                .glassCard()
                .onAppear {
                    if pageReachedText.isEmpty, let book = selectedBookForSession {
                        pageReachedText = "\(book.currentPage)"
                    }
                }
            } else if readingTimer.isActive {
                VStack(spacing: 12) {
                    Text(timeLabel(readingTimer.remainingSeconds))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .monospacedDigit()
                    ProgressView(value: readingTimer.progress).tint(.orange)
                    if let book = selectedBookForSession {
                        Text(book.title)
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    pauseCancelRow(for: readingTimer)
                }
                .glassCard()
            } else {
                backButton
            }
        }
    }

    private func saveReadingSession() {
        guard let book = selectedBookForSession, let page = Int(pageReachedText) else { return }
        let minutes = Int(readingTimer.totalDuration / 60)
        let session = ReadingSession(date: Date(), bookID: book.id, minutesRead: minutes, pageReached: page)
        modelContext.insert(session)
        book.currentPage = book.totalPages > 0 ? min(page, book.totalPages) : page
        if book.totalPages > 0 && page >= book.totalPages {
            book.isCompleted = true
            book.completedAt = .now
        }
        try? modelContext.save()

        Haptics.success()
                refreshExternalState()

                readingTimer.markConsumed()
                pageReachedText = ""
                selectedBookForSession = nil
                activeFlow = nil
    }

    // MARK: - Altro

    private var customFlowCard: some View {
        VStack(spacing: 12) {
            if customTimer.isCompleted {
                Button {
                    Haptics.action()
                    showSecondCamera = true
                } label: {
                    Label("Take the picture!", systemImage: "camera.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundStyle(.white)
                        .background(Color.orange, in: RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .orange.opacity(0.35), radius: 14, y: 6)
                }
            } else if customTimer.isActive {
                VStack(spacing: 12) {
                    Text(timeLabel(customTimer.remainingSeconds))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .monospacedDigit()
                    ProgressView(value: customTimer.progress).tint(.orange)
                    pauseCancelRow(for: customTimer)
                }
                .glassCard()
            } else {
                backButton
                VStack(spacing: 14) {
                    Text(profiles.first?.customActivityName ?? "Activities")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Button {
                                            Haptics.action()
                                            let minutes = profiles.first?.customActivityDurationMinutes ?? 30
                                            customTimer.start(minutes: minutes)
                                        } label: {
                        Label("Start", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundStyle(.white)
                            .background(Color.orange, in: RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .orange.opacity(0.35), radius: 14, y: 6)
                    }
                }
            }
        }
    }

    private func saveCustomActivity(_ image: UIImage) {
        guard let fileName = ImageStore.save(image) else { return }
        let minutes = Int(customTimer.totalDuration / 60)
        let entry = CustomActivityEntry(date: Date(), imageFileName: fileName, durationMinutes: minutes)
        modelContext.insert(entry)
        try? modelContext.save()

        Haptics.success()
                refreshExternalState()

                customTimer.markConsumed()
                activeFlow = nil
    }

    // MARK: - Widget / notifiche / Firestore

    private func refreshExternalState(newStudyEntry: StudyEntry? = nil, freshPhoto: UIImage? = nil) {
        let currentAggregation = ActivityAggregator.aggregate(
            selectedActivities: selectedActivities,
            studyEntries: newStudyEntry.map { entries + [$0] } ?? entries,
            trainingEntries: trainingEntries,
            readingSessions: readingSessions,
            customEntries: customEntries
        )
        let updatedStats = StreakCalculator.stats(completedDates: currentAggregation.completedDates)

        NotificationScheduler.shared.refreshSchedule(todayDone: updatedStats.todayDone)

        let line = MotivationalNotifications.streakIdentityLine(forDays: updatedStats.currentStreak)
        WidgetSnapshotStore.save(
            StreakSnapshot(
                currentStreak: updatedStats.currentStreak,
                bestStreak: updatedStats.bestStreak,
                todayDone: updatedStats.todayDone,
                motivationalLine: line,
                updatedAt: Date()
            )
        )
        WidgetCenter.shared.reloadAllTimelines()

        guard let profile = profiles.first else { return }
        Task {
            try? await FriendLookupService.publishMyProfile(
                friendCode: profile.friendCode,
                username: profile.username,
                currentStreak: updatedStats.currentStreak,
                bestStreak: updatedStats.bestStreak,
                lastEntryDate: Date(),
                latestPhoto: freshPhoto
            )
        }
        if let milestone = MilestoneTracker.checkAndConsume(currentStreak: updatedStats.currentStreak) {
            celebratingMilestone = (milestone, updatedStats.currentStreak)
        }
    }
}
