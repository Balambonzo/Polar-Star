//StudyTimerController
import Foundation
import SwiftUI
import Observation
import UIKit
import AudioToolbox

@Observable
final class StudyTimerController {

    private let id: String
    private var storageKey: String { "studyTimerState_v2_\(id)" }

    private(set) var totalDuration: TimeInterval = 0
    private(set) var accumulatedSeconds: TimeInterval = 0
    private(set) var isActive = false
    private(set) var isCompleted = false
    private(set) var isPaused = false

    private var tickTimer: Timer?
    private var backgroundedAt: Date?
    private var deviceWasLockedThisBackgroundPeriod = false
    private var lockObserver: NSObjectProtocol?

    /// Ora persiste anche `backgroundedAt` e il flag di blocco — prima
    /// vivevano solo in memoria e si perdevano se iOS terminava l'app
    /// mentre era in background per un periodo lungo, impedendo il
    /// recupero del tempo al rientro.
    private struct PersistedState: Codable {
        var day: Date
        var totalDuration: TimeInterval
        var accumulatedSeconds: TimeInterval
        var isActive: Bool
        var isCompleted: Bool
        var isPaused: Bool
        var backgroundedAt: Date?
        var wasLockedWhenBackgrounded: Bool
    }

    var remainingSeconds: Int {
        max(0, Int((totalDuration - accumulatedSeconds).rounded()))
    }

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return min(1, accumulatedSeconds / totalDuration)
    }

    init(id: String) {
        self.id = id
        loadIfSameDay()
        lockObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.protectedDataWillBecomeUnavailableNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.deviceWasLockedThisBackgroundPeriod = true
            self.persist()
        }
    }

    deinit {
        if let lockObserver { NotificationCenter.default.removeObserver(lockObserver) }
    }

    func start(minutes: Int) {
        totalDuration = TimeInterval(minutes * 60)
        accumulatedSeconds = 0
        isActive = true
        isCompleted = false
        isPaused = false
        persist()
        startTicking()
    }

    func pause() {
        guard isActive, !isCompleted, !isPaused else { return }
        isPaused = true
        stopTicking()
        persist()
    }

    func resume() {
        guard isActive, !isCompleted, isPaused else { return }
        isPaused = false
        startTicking()
        persist()
    }

    func cancel() {
        stopTicking()
        totalDuration = 0
        accumulatedSeconds = 0
        isActive = false
        isCompleted = false
        isPaused = false
        backgroundedAt = nil
        deviceWasLockedThisBackgroundPeriod = false
        persist()
    }

    func markConsumed() {
        stopTicking()
        totalDuration = 0
        accumulatedSeconds = 0
        isActive = false
        isCompleted = false
        isPaused = false
        backgroundedAt = nil
        deviceWasLockedThisBackgroundPeriod = false
        persist()
    }

    func handleScenePhase(_ phase: ScenePhase) {
        // Se il timer è in pausa esplicita, i cambi di scena non devono
        // avere alcun effetto: né far avanzare il tempo, né far ripartire
        // il ticking. Solo resume() può farlo ripartire.
        guard isActive, !isCompleted, !isPaused else { return }

        switch phase {
        case .active:
            if deviceWasLockedThisBackgroundPeriod, let capturedBackgroundedAt = backgroundedAt {
                let elapsed = Date().timeIntervalSince(capturedBackgroundedAt)
                accumulatedSeconds = min(totalDuration, accumulatedSeconds + elapsed)
                if accumulatedSeconds >= totalDuration {
                    completeAndNotify()
                }
            }
            // Sempre azzerati e persistiti qui, PRIMA di ripartire — così
            // non restano mai valori "vecchi" salvati su disco che
            // potrebbero essere riusati per errore a un riavvio successivo.
            backgroundedAt = nil
            deviceWasLockedThisBackgroundPeriod = false
            persist()
            if !isCompleted {
                startTicking()
            }
        case .background:
            // NON resettare deviceWasLockedThisBackgroundPeriod qui: non
            // c'è un ordine garantito tra questa transizione e la notifica
            // protectedDataWillBecomeUnavailableNotification. Se il flag
            // è già stato impostato a true dalla notifica (arrivata prima
            // di questo evento), resettarlo qui trasformerebbe per errore
            // un vero blocco schermo in uno switch di app, fermando il
            // timer quando invece dovrebbe continuare a correre.
            if backgroundedAt == nil {
                backgroundedAt = Date()
            }
            stopTicking()
            persist()
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    private func startTicking() {
        guard tickTimer == nil else { return }
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func stopTicking() {
        tickTimer?.invalidate()
        tickTimer = nil
    }

    private func tick() {
        accumulatedSeconds += 1
        if accumulatedSeconds >= totalDuration {
            accumulatedSeconds = totalDuration
            completeAndNotify()
        }
        persist()
    }

    private func completeAndNotify() {
        guard !isCompleted else { return }
        isCompleted = true
        stopTicking()
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    private func persist() {
        let state = PersistedState(
            day: Calendar.current.startOfDay(for: .now),
            totalDuration: totalDuration,
            accumulatedSeconds: accumulatedSeconds,
            isActive: isActive,
            isCompleted: isCompleted,
            isPaused: isPaused,
            backgroundedAt: backgroundedAt,
            wasLockedWhenBackgrounded: deviceWasLockedThisBackgroundPeriod
        )
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadIfSameDay() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let state = try? JSONDecoder().decode(PersistedState.self, from: data) else { return }

        guard Calendar.current.isDateInToday(state.day) else {
            UserDefaults.standard.removeObject(forKey: storageKey)
            return
        }

        totalDuration = state.totalDuration
        accumulatedSeconds = state.accumulatedSeconds
        isActive = state.isActive
        isCompleted = state.isCompleted
        isPaused = state.isPaused
        backgroundedAt = state.backgroundedAt
        deviceWasLockedThisBackgroundPeriod = state.wasLockedWhenBackgrounded
    }
}
