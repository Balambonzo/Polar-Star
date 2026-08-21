//TodayView.swift
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
    @State private var showProfile = false
    @State private var showWeeklyReview = false

    @State private var studyTheoryTimer = StudyTimerController(id: "studyTheory")
    @State private var studyExerciseTimer = StudyTimerController(id: "studyExercise")
    @State private var studyTheoryPercent: Double = 50
    
    @State private var readingTimer = StudyTimerController(id: "reading")
    @State private var customTimer = StudyTimerController(id: "custom")
    
    @State private var trainingController: TrainingWorkoutController?
    @State private var activeTrainingEntry: TrainingEntry?
    @State private var showTrainingWorkout = false

    @State private var selectedDurationMinutes = 15
    @State private var pageReachedText = ""
    @State private var selectedBookForSession: Book?

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
        case ActivityKey.training.rawValue:
            return trainingEntries.contains {
                $0.isCompleted &&
                Calendar.current.startOfDay(for: $0.date) == today
            }
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
    
    /// Domenica non è prevista dalla scheda advanced: si può solo
    /// segnare come giorno di riposo, non c'è un allenamento da avviare.
    private var isRestDay: Bool {
        currentTrainingLevel == .advanced &&
        Calendar.current.component(.weekday, from: Date()) == 1   // 1 = domenica
    }
    
    /// Lunedì-Venerdì per gli utenti advanced usano la scheda fissa;
    /// sabato e domenica restano a scelta libera (vecchio flusso).
    private var isFixedTrainingDay: Bool {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return (2...6).contains(weekday)
    }

    /// La Weekly Review compare in alto a sinistra solo la domenica.
    private var isSunday: Bool {
        Calendar.current.component(.weekday, from: Date()) == 1   // 1 = domenica
    }

    /// Fuori dalla toolbar, così può essere grande quanto vogliamo e resta
    /// un cerchio vero (nella toolbar veniva schiacciato/ovalizzato).
    private var profileBubble: some View {
        Button {
            Haptics.tap()
            showProfile = true
        } label: {
            ZStack {
                Circle().fill(Color.white.opacity(0.06))
                if let path = profiles.first?.profileImagePath, let uiImage = ImageStore.load(path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .frame(width: 48, height: 48)
            .overlay(Circle().stroke(Theme.cardBorder, lineWidth: 1))
            .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }

    var body: some View {
 //       let _ = Self._printChanges()
        NavigationStack {
            ZStack {
                StarfieldBackground()
                ScrollView {
                    VStack(spacing: 28) {
                        Spacer(minLength: 20)
                        
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
                        
                        Spacer(minLength: 20)
                        
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
                    .frame(maxWidth: .infinity)
                    .background {
//                        RenderMotionProbe(name: "Today scroll content")
//                            .frame(width: 1, height: 1)
//                            .allowsHitTesting(false)
                    }
                }
                .scrollBounceBehavior(.basedOnSize) // niente rimbalzo se il contenuto entra tutto
                .transaction {
                    $0.scrollContentOffsetAdjustmentBehavior = .disabled
                }
            }
            .overlay(alignment: .topTrailing) {
                profileBubble
                    .padding(.top, 54)   // sotto la nav bar, non dentro
                    .padding(.trailing, 20)
            }
            .dismissKeyboardOnTap()
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline) // titolo fisso e piccolo, sempre sopra il contenuto
            .fontDesign(.rounded)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                if isSunday {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            Haptics.tap()
                            showWeeklyReview = true
                        } label: {
                            Image(systemName: "calendar")
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
            .sheet(isPresented: $showWeeklyReview) {
                WeeklyReviewView()
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                    appeared = true
                }
                Task {
                    await BackupSyncService.restoreStudyEntriesIfNeeded(context: modelContext, currentEntries: entries)
                    if !entries.isEmpty {
                        BackupSyncService.backupStudyEntries(entries)
                    }
                }
                studyTheoryTimer.handleScenePhase(scenePhase)
                studyExerciseTimer.handleScenePhase(scenePhase)
                readingTimer.handleScenePhase(scenePhase)
                customTimer.handleScenePhase(scenePhase)
            }
            .onChange(of: scenePhase) { _, newPhase in
                studyTheoryTimer.handleScenePhase(newPhase)
                studyExerciseTimer.handleScenePhase(newPhase)
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
            .fullScreenCover(isPresented: $showTrainingWorkout) {
                if let controller = trainingController,
                   let entry = activeTrainingEntry {
                    
                    TrainingWorkoutView(
                        controller: controller,
                        trainingEntry: entry,
                        onFinish: {
                            finishTrainingWorkout()
                        },
                        onCancel: {
                            cancelTrainingWorkout()
                        }
                    )
                }
            }
            .sheet(isPresented: $showTrainingSetup) {
                if let profile = profiles.first {
                    if currentTrainingLevel == .advanced && isFixedTrainingDay {
                        AdvancedWorkoutSummaryView { exercises in
                            startTraining(exercises: exercises)
                            showTrainingSetup = false
                        }
                    } else {
                        TrainingSessionSetupView(
                            profile: profile,
                            level: currentTrainingLevel
                        ) { exercises in
                            startTraining(exercises: exercises)
                            showTrainingSetup = false
                        }
                    }
                }
            }
        }
    }

    // MARK: - Scelta attività

    private var activityChoiceGrid: some View {
        VStack(spacing: 12) {
            ForEach(Array(pendingActivities.enumerated()), id: \.element) { index, key in
                Button {
                    Haptics.selection()
                    select(key)
                } label: {
                    activityChoiceRow(icon: icon(for: key), title: title(for: key), subtitle: subtitle(for: key))
                }
                .buttonStyle(PressableButtonStyle())   // <-- prima era .pressable()
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
            }
        }
    }

        private func subtitle(for key: String) -> String {
            switch key {
            case ActivityKey.study.rawValue:
                return "Sessione a tempo, poi una foto"
            case ActivityKey.training.rawValue:
                return "Livello \(currentTrainingLevel.displayName)"
            case ActivityKey.reading.rawValue:
                return "Continua il tuo libro"
            default:
                let minutes = profiles.first?.customActivityDurationMinutes ?? 30
                return "\(minutes) minuti"
            }
        }

        private func activityChoiceRow(icon: String, title: String, subtitle: String) -> some View {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [.orange, .orange.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: .orange.opacity(0.4), radius: 10, y: 4)
                    Image(systemName: icon)
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(colors: [Color.orange.opacity(0.25), .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1
                    )
            )
        }

    private func select(_ key: String) {
        switch key {
        case ActivityKey.study.rawValue:
            activeFlow = .study
        case ActivityKey.training.rawValue:
            activeFlow = .training
            if !isRestDay {
                showTrainingSetup = true
            }
        case ActivityKey.reading.rawValue:
            activeFlow = .reading
            showReadingSetup = true
        default:
            activeFlow = .custom
        }
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
            if studyExerciseTimer.isCompleted {
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
            } else if studyExerciseTimer.isActive {
                VStack(spacing: 12) {
                    Text("EXERCISES")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.orange)
                    Text(timeLabel(studyExerciseTimer.remainingSeconds))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .monospacedDigit()
                    ProgressView(value: studyExerciseTimer.progress).tint(.orange)
                    pauseCancelRow(for: studyExerciseTimer)
                }
                .glassCard()
            } else if studyTheoryTimer.isCompleted {
                VStack(spacing: 14) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.green)
                    Text("Theory done!")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text("Ready to move on to exercises?")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                    Button {
                        Haptics.action()
                        let exerciseMinutes = Int(studyExerciseTimer.totalDuration / 60)
                        let fallback = max(1, selectedDurationMinutes - Int(studyTheoryTimer.totalDuration / 60))
                        studyExerciseTimer.start(minutes: exerciseMinutes > 0 ? exerciseMinutes : fallback)
                    } label: {
                        Label("Start exercises", systemImage: "pencil")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundStyle(.white)
                            .background(Color.orange, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .glassCard()
            } else if studyTheoryTimer.isActive {
                VStack(spacing: 12) {
                    Text("THEORY")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.orange)
                    Text(timeLabel(studyTheoryTimer.remainingSeconds))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .monospacedDigit()
                    ProgressView(value: studyTheoryTimer.progress).tint(.orange)
                    Text("Don't open any other apps or the timer will stop!")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                    pauseCancelRow(for: studyTheoryTimer)
                }
                .glassCard()
            } else {
                backButton
                VStack(spacing: 16) {
                    Text("How much today boss?")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                    Picker("Total", selection: $selectedDurationMinutes) {
                        ForEach(Array(stride(from: 15, through: 180, by: 15)), id: \.self) { minutes in
                            Text(durationLabel(minutes)).tag(minutes)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)

                    VStack(spacing: 8) {
                        HStack {
                            Text("Theory")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                            Spacer()
                            Text("Exercises")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Slider(value: $studyTheoryPercent, in: 0...100, step: 5)
                            .tint(.orange)
                        Text("\(theoryMinutesPreview) min theory · \(exerciseMinutesPreview) min exercises")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }

                    Button {
                        Haptics.action()
                        studyTheoryTimer.start(minutes: max(1, theoryMinutesPreview))
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

    private var theoryMinutesPreview: Int {
        Int((Double(selectedDurationMinutes) * studyTheoryPercent / 100).rounded())
    }

    private var exerciseMinutesPreview: Int {
        max(0, selectedDurationMinutes - theoryMinutesPreview)
    }

    private func save(_ image: UIImage) {
        guard let fileName = ImageStore.save(image) else { return }
        let theoryMinutes = Int(studyTheoryTimer.totalDuration / 60)
        let exerciseMinutes = Int(studyExerciseTimer.totalDuration / 60)
        let totalMinutes = theoryMinutes + exerciseMinutes
        let entry = StudyEntry(
            date: Date(),
            imageFileName: fileName,
            studyDurationMinutes: totalMinutes,
            theoryMinutes: theoryMinutes,
            exerciseMinutes: exerciseMinutes
        )
        modelContext.insert(entry)
        try? modelContext.save()
        BackupSyncService.backupStudyEntries(entries + [entry], freshEntry: entry, freshImage: image)

        Haptics.success()
        refreshExternalState(newStudyEntry: entry, freshPhoto: image)

        studyTheoryTimer.markConsumed()
        studyExerciseTimer.markConsumed()
        activeFlow = nil
    }

    // MARK: - Allenamento

    private var trainingFlowCard: some View {
        Group {
            if isRestDay {
                restDayCard
            } else {
                backButton
            }
        }
    }

    private var restDayCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)

            Text("Enjoy the rest")
                .font(.title3.bold())
                .foregroundStyle(Theme.textPrimary)

            Text("Sunday is a rest day on your program. Recovery counts too.")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                Haptics.success()
                completeRestDay()
            } label: {
                Text("Mark as done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(.white)
                    .background(Color.orange, in: RoundedRectangle(cornerRadius: 16))
            }

            backButton
        }
        .glassCard()
    }

    private func startTraining(exercises: [ExerciseDefinition]) {
        guard !exercises.isEmpty else {
            return
        }

        let startedAt = Date()

        let muscleGroups = Array(
            Set(exercises.map(\.muscleGroup))
        )
        .sorted()

        let entry = TrainingEntry(
            date: startedAt,
            muscleGroups: muscleGroups,
            level: currentTrainingLevel,
            startedAt: startedAt
        )

        for (index, definition) in exercises.enumerated() {
            let exercise = TrainingExercise(
                name: definition.name,
                muscleGroup: definition.muscleGroup,
                cue: definition.cue,
                mode: definition.mode,
                targetSets: definition.targetSets,
                targetReps: definition.targetReps,
                targetHoldSeconds: definition.targetHoldSeconds,
                restSeconds: definition.restSeconds,
                order: index
            )

            entry.exercises.append(exercise)
            modelContext.insert(exercise)
        }

        modelContext.insert(entry)

        try? modelContext.save()

        activeTrainingEntry = entry

        let controller = TrainingWorkoutController(
            exercises: exercises
        )

        trainingController = controller
        controller.start()

        showTrainingWorkout = true
    }
    
    private func completeRestDay() {
        let now = Date()
        let entry = TrainingEntry(
            date: now,
            muscleGroups: [],
            level: currentTrainingLevel,
            startedAt: now
        )
        entry.isCompleted = true
        entry.completedAt = now
        entry.durationMinutes = 0

        modelContext.insert(entry)
        try? modelContext.save()

        refreshExternalState()
        activeFlow = nil
    }
    
    private func finishTrainingWorkout() {
        guard let entry = activeTrainingEntry else {
            return
        }

        let elapsed = Date().timeIntervalSince(entry.startedAt)

        entry.durationMinutes = max(
            1,
            Int(round(elapsed / 60.0))
        )

        entry.isCompleted = true
        entry.completedAt = Date()

        advanceTrainingProgress(
            for: entry.muscleGroups
        )
        
        profiles.first?.recordPumpWorkout(muscles: entry.muscleGroups)   // ← nuovo

        try? modelContext.save()

        Haptics.success()
        refreshExternalState()

        trainingController = nil
        activeTrainingEntry = nil
        showTrainingWorkout = false
        activeFlow = nil
    }

    private func cancelTrainingWorkout() {
        if let entry = activeTrainingEntry {
            modelContext.delete(entry)
            try? modelContext.save()
        }

        trainingController?.cancel()

        trainingController = nil
        activeTrainingEntry = nil
        showTrainingWorkout = false
        activeFlow = nil
    }
    
    private func advanceTrainingProgress(for muscles: [String]) {
        guard currentTrainingLevel != .advanced else { return }   // ← nuovo
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
        let profileImage = profile.profileImagePath.flatMap { ImageStore.load($0) }   // ← nuovo
        Task {
            try? await FriendLookupService.publishMyProfile(
                friendCode: profile.friendCode,
                username: profile.username,
                currentStreak: updatedStats.currentStreak,
                bestStreak: updatedStats.bestStreak,
                lastEntryDate: Date(),
                profileImage: profileImage,   // ← nuovo
                latestPhoto: freshPhoto
            )
        }
        if let milestone = MilestoneTracker.checkAndConsume(currentStreak: updatedStats.currentStreak) {
            celebratingMilestone = (milestone, updatedStats.currentStreak)
        }
    }
}
