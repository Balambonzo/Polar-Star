import Foundation
import SwiftData
import UIKit

/// Rappresentazione "da backup" di una StudyEntry — stessi campi del
/// modello SwiftData, ma è una struct Codable indipendente: così il
/// formato del backup non si rompe se un giorno cambi il @Model.
struct StudyEntryBackup: Codable {
    let id: UUID
    let date: Date
    let imageFileName: String
    let createdAt: Date
    let studyDurationMinutes: Int
}

enum BackupSyncService {
    /// Da chiamare ogni volta che salvi/modifichi una sessione di studio:
    /// spedisce l'intero elenco aggiornato (non solo la voce nuova) più,
    /// se presente, la foto appena scattata. Fallisce in silenzio se il
    /// Mac non è raggiungibile — i dati restano comunque salvati in locale.
    static func backupStudyEntries(_ entries: [StudyEntry], freshEntry: StudyEntry? = nil, freshImage: UIImage? = nil) {
        Task {
            guard await PocketBaseClient.shared.isAuthenticated else { return }

            let payload = entries.map {
                StudyEntryBackup(
                    id: $0.id,
                    date: $0.date,
                    imageFileName: $0.imageFileName,
                    createdAt: $0.createdAt,
                    studyDurationMinutes: $0.studyDurationMinutes
                )
            }
            try? await PocketBaseClient.shared.pushBackup(kind: "studyEntries", payload: payload)

            if let freshEntry, let freshImage {
                try? await PocketBaseClient.shared.uploadPhoto(image: freshImage, filename: freshEntry.imageFileName)
            }
        }
    }

    /// Da chiamare all'avvio dell'app: se non c'è NESSUNA StudyEntry in
    /// locale (caso tipico dopo una reinstallazione), prova a ripristinarle
    /// dal backup remoto insieme alle relative foto.
    @MainActor
    static func restoreStudyEntriesIfNeeded(context: ModelContext, currentEntries: [StudyEntry]) async {
        guard currentEntries.isEmpty else { return }

        await PocketBaseClient.shared.restoreSessionIfPossible()
        guard await PocketBaseClient.shared.isAuthenticated else { return }

        guard let backups = try? await PocketBaseClient.shared.pullBackup(kind: "studyEntries", as: StudyEntryBackup.self),
              !backups.isEmpty else { return }

        if let photos = try? await PocketBaseClient.shared.downloadAllPhotos() {
            for photo in photos {
                ImageStore.save(photo.image, withFileName: photo.filename)
            }
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
