import Foundation
import SwiftData

/// Cache locale di un amico. Non è sincronizzata via CloudKit (vive in un
/// ModelConfiguration separato, locale): è solo lo specchio di ciò che è
/// stato letto dal suo profilo pubblico, quindi qui @Attribute(.unique)
/// resta valido — non tocca lo store CloudKit.
@Model
final class Friend {
    @Attribute(.unique)
    var id: UUID

    @Attribute(.unique)
    var friendCode: String

    var username: String
    var profileImagePath: String?
    var currentStreak: Int
    var bestStreak: Int
    var lastEntryDate: Date?
    var createdAt: Date

    init(username: String, friendCode: String) {
        self.id = UUID()
        self.username = username
        self.friendCode = friendCode
        self.profileImagePath = nil
        self.currentStreak = 0
        self.bestStreak = 0
        self.lastEntryDate = nil
        self.createdAt = .now
    }
}
