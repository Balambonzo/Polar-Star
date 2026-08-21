import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID = UUID()
    var fullName: String = ""
    var username: String = ""
    var friendCode: String = ""
    var profileImagePath: String? = nil
    var goal: String? = nil
    var memberSince: Date = Date()
    var totalStudySeconds: Double = 0
    var totalSessions: Int = 0
    var hasCompletedOnboarding: Bool = false

    var selectedActivities: [String] = []
    var trainingLevel: String? = nil
    var customActivityName: String? = nil
    var customActivityDurationMinutes: Int? = nil
    var dailyReadingMinimumMinutes: Int? = nil

    var initialMuscleLevelsData: Data? = nil
    var trainingProgressData: Data? = nil

    init(fullName: String = "", username: String = "", friendCode: String) {
        self.id = UUID()
        self.fullName = fullName
        self.username = username
        self.friendCode = friendCode
        self.profileImagePath = nil
        self.goal = nil
        self.memberSince = .now
        self.totalStudySeconds = 0
        self.totalSessions = 0
        self.hasCompletedOnboarding = false
        self.selectedActivities = []
    }

    var initialMuscleLevels: [String: Int] {
        get {
            guard let data = initialMuscleLevelsData,
                  let dict = try? JSONDecoder().decode([String: Int].self, from: data) else { return [:] }
            return dict
        }
        set {
            initialMuscleLevelsData = try? JSONEncoder().encode(newValue)
        }
    }

    struct MuscleProgress: Codable {
        var chainIndex: Int = 0
        var sessionsAtLevel: Int = 0
    }

    var trainingProgress: [String: MuscleProgress] {
        get {
            guard let data = trainingProgressData,
                  let dict = try? JSONDecoder().decode([String: MuscleProgress].self, from: data) else { return [:] }
            return dict
        }
        set {
            trainingProgressData = try? JSONEncoder().encode(newValue)
        }
    }
    
    // Dentro la classe UserProfile, vicino a trainingProgressData:
    var pumpLevelsData: Data? = nil

    struct MuscleLevel: Codable {
        var level: Double        // 0...maxPumpLevel
        var lastTrainedDate: Date
    }

    var pumpLevels: [String: MuscleLevel] {
        get {
            guard let data = pumpLevelsData,
                  let dict = try? JSONDecoder().decode([String: MuscleLevel].self, from: data) else { return [:] }
            return dict
        }
        set {
            pumpLevelsData = try? JSONEncoder().encode(newValue)
        }
    }

    static let maxPumpLevel: Double = 20

    /// Livello effettivo di un muscolo ORA, applicando il decadimento
    /// (1 livello perso ogni 3 giorni consecutivi senza allenarlo).
    func effectivePumpLevel(for muscle: String, now: Date = .now) -> Double {
        guard let entry = pumpLevels[muscle] else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: entry.lastTrainedDate, to: now).day ?? 0
        let decayed = entry.level - Double(days / 3)
        return max(0, min(decayed, UserProfile.maxPumpLevel))
    }

    /// Da chiamare a fine workout: +1 livello per ogni muscolo coinvolto,
    /// massimo un incremento al giorno per muscolo.
    func recordPumpWorkout(muscles: [String], now: Date = .now) {
        var levels = pumpLevels
        for muscle in muscles {
            let current = effectivePumpLevel(for: muscle, now: now)
            let alreadyTrainedToday = levels[muscle].map { Calendar.current.isDate($0.lastTrainedDate, inSameDayAs: now) } ?? false
            guard !alreadyTrainedToday else { continue }
            let newLevel = min(current + 1, UserProfile.maxPumpLevel)
            levels[muscle] = MuscleLevel(level: newLevel, lastTrainedDate: now)
        }
        pumpLevels = levels
    }
}

enum UserProfileStore {
    @discardableResult
    static func fetchOrCreate(in context: ModelContext) -> UserProfile {
        let descriptor = FetchDescriptor<UserProfile>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let profile = UserProfile(friendCode: FriendCodeGenerator.generate())
        context.insert(profile)
        try? context.save()
        return profile
    }
}
