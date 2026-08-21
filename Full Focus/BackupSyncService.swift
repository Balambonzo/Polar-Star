import Foundation
import SwiftData
import UIKit

struct StudyEntryBackup: Codable {
    let id: UUID
    let date: Date
    let imageFileName: String
    let createdAt: Date
    let studyDurationMinutes: Int
}

struct TrainingEntryBackup: Codable {
    let id: UUID
    let date: Date
    let muscleGroups: [String]
    let level: String
    let durationMinutes: Int
    let isCompleted: Bool
    let startedAt: Date
    let completedAt: Date?
}

struct ReadingSessionBackup: Codable {
    let id: UUID
    let date: Date
    let bookID: UUID
    let minutesRead: Int
    let pageReached: Int
}

struct CustomActivityEntryBackup: Codable {
    let id: UUID
    let date: Date
    let imageFileName: String
    let durationMinutes: Int
}

enum BackupSyncService {

    static func backupStudyEntries(_ entries: [StudyEntry], freshEntry: StudyEntry? = nil, freshImage: UIImage? = nil) {
        Task {
            guard await PocketBaseClient.shared.isAuthenticated else { return }
            let payload = entries.map {
                StudyEntryBackup(id: $0.id, date: $0.date, imageFileName: $0.imageFileName, createdAt: $0.createdAt, studyDurationMinutes: $0.studyDurationMinutes)
            }
            try? await PocketBaseClient.shared.pushBackup(kind: "studyEntries", payload: payload)
            if let freshEntry, let freshImage {
                try? await PocketBaseClient.shared.uploadPhoto(image: freshImage, filename: freshEntry.imageFileName)
            }
        }
    }

    static func backupTrainingEntries(_ entries: [TrainingEntry]) {
        Task {
            guard await PocketBaseClient.shared.isAuthenticated else { return }
            let payload = entries.map {
                TrainingEntryBackup(id: $0.id, date: $0.date, muscleGroups: $0.muscleGroups, level: $0.level, durationMinutes: $0.durationMinutes, isCompleted: $0.isCompleted, startedAt: $0.startedAt, completedAt: $0.completedAt)
            }
            try? await PocketBaseClient.shared.pushBackup(kind: "trainingEntries", payload: payload)
        }
    }

    static func backupReadingSessions(_ sessions: [ReadingSession]) {
        Task {
            guard await PocketBaseClient.shared.isAuthenticated else { return }
            let payload = sessions.map {
                ReadingSessionBackup(id: $0.id, date: $0.date, bookID: $0.bookID, minutesRead: $0.minutesRead, pageReached: $0.pageReached)
            }
            try? await PocketBaseClient.shared.pushBackup(kind: "readingSessions", payload: payload)
        }
    }

    static func backupCustomEntries(_ entries: [CustomActivityEntry], freshEntry: CustomActivityEntry? = nil, freshImage: UIImage? = nil) {
        Task {
            guard await PocketBaseClient.shared.isAuthenticated else { return }
            let payload = entries.map {
                CustomActivityEntryBackup(id: $0.id, date: $0.date, imageFileName: $0.imageFileName, durationMinutes: $0.durationMinutes)
            }
            try? await PocketBaseClient.shared.pushBackup(kind: "customEntries", payload: payload)
            if let freshEntry, let freshImage {
                try? await PocketBaseClient.shared.uploadPhoto(image: freshImage, filename: freshEntry.imageFileName)
            }
        }
    }

    /// Da chiamare subito dopo un login riuscito: spedisce TUTTO quello
    /// che già esiste in locale, non solo le voci future.
    static func backupEverythingNow(
        studyEntries: [StudyEntry],
        trainingEntries: [TrainingEntry],
        readingSessions: [ReadingSession],
        customEntries: [CustomActivityEntry]
    ) {
        backupStudyEntries(studyEntries)
        backupTrainingEntries(trainingEntries)
        backupReadingSessions(readingSessions)
        backupCustomEntries(customEntries)
    }

    @MainActor
    static func restoreStudyEntriesIfNeeded(context: ModelContext, currentEntries: [StudyEntry]) async {
        guard currentEntries.isEmpty else { return }
        await PocketBaseClient.shared.restoreSessionIfPossible()
        guard await PocketBaseClient.shared.isAuthenticated else { return }
        guard let backups = try? await PocketBaseClient.shared.pullBackup(kind: "studyEntries", as: StudyEntryBackup.self), !backups.isEmpty else { return }
        if let photos = try? await PocketBaseClient.shared.downloadAllPhotos() {
            for photo in photos { ImageStore.save(photo.image, withFileName: photo.filename) }
        }
        for item in backups {
            let entry = StudyEntry(date: item.date, imageFileName: item.imageFileName, studyDurationMinutes: item.studyDurationMinutes)
            entry.id = item.id
            entry.createdAt = item.createdAt
            context.insert(entry)
        }
        try? context.save()
    }
}
