import Foundation

struct StreakSnapshot: Codable {
    let currentStreak: Int
    let bestStreak: Int
    let todayDone: Bool
    let motivationalLine: String
    let updatedAt: Date
}

enum WidgetSnapshotStore {
    private static let appGroupID = "group.com.albotosco.fullfocus.beta"
    private static let key = "streakSnapshot"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func save(_ snapshot: StreakSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults?.set(data, forKey: key)
    }

    static func load() -> StreakSnapshot? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(StreakSnapshot.self, from: data)
    }
}
