import Foundation
import SwiftData

@Model
final class Friend {
    @Attribute(.unique)
    var id: UUID

    @Attribute(.unique)
    var friendCode: String

    var username: String
    var profileImagePath: String?      // foto profilo vera
    var latestPhotoPath: String?       // ← nuovo: ultima foto attività
    var currentStreak: Int
    var bestStreak: Int
    var lastEntryDate: Date?
    var createdAt: Date

    init(username: String, friendCode: String) {
        self.id = UUID()
        self.username = username
        self.friendCode = friendCode
        self.profileImagePath = nil
        self.latestPhotoPath = nil     // ← nuovo
        self.currentStreak = 0
        self.bestStreak = 0
        self.lastEntryDate = nil
        self.createdAt = .now
    }
}
