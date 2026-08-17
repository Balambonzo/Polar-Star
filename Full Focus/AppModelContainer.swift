import Foundation
import SwiftData

/// Un unico ModelContainer, interamente locale. Nessun backup su iCloud:
/// StudyEntry, UserProfile e Friend vivono solo sul dispositivo.
enum AppModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([
            StudyEntry.self,
            UserProfile.self,
            Friend.self,
            TrainingEntry.self,
            TrainingExercise.self,
            TrainingSet.self,
            CustomActivityEntry.self,
            Book.self,
            ReadingSession.self
        ])
        let config = ModelConfiguration(schema: schema)

        if let container = try? ModelContainer(for: schema, configurations: [config]) {
            return container
        }

        // Lo store esistente non è più leggibile (es. corrotto dopo un
        // update, o migrazione fallita). Invece di crashare sempre
        // all'avvio, lo eliminiamo e ripartiamo da uno store vuoto:
        // l'utente perde lo storico locale, ma l'app resta usabile.
        print("⚠️ AppModelContainer: store non leggibile, provo a ricrearlo da zero.")
        deleteExistingStore(at: config.url)

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Anche dopo il reset non si riesce a creare il container:
            // a questo punto è un problema di sistema (es. disco pieno
            // o permessi), non recuperabile qui.
            fatalError("Impossible to create the container even after reset: \(error)")
        }
    }()

    private static func deleteExistingStore(at url: URL) {
        let fileManager = FileManager.default
        // SwiftData/SQLite usa 3 file affiancati: il -wal e -shm vanno
        // rimossi insieme al file principale o la nuova apertura fallisce.
        let suffixes = ["", "-wal", "-shm"]
        for suffix in suffixes {
            let fileURL = URL(fileURLWithPath: url.path + suffix)
            try? fileManager.removeItem(at: fileURL)
        }
    }
}
