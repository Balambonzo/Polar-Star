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
