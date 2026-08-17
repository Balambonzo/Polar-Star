import UIKit


extension ImageStore {
    /// Come `save(_:)`, ma con un nome file specifico invece che casuale —
    /// serve in fase di ripristino per far coincidere il filename con
    /// quello già referenziato dalle entries scaricate dal backup.
    @discardableResult
    static func save(_ image: UIImage, withFileName fileName: String) -> String? {
        let url = directory.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        do {
            try data.write(to: url)
            return fileName
        } catch {
            return nil
        }
    }
}

/// Salva e carica le foto della streak come file .jpg dentro Documents/StreakPhotos.
/// Tutto locale, niente cloud, niente rete: solo il telefono.
enum ImageStore {
    static var directory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("StreakPhotos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    @discardableResult
    static func save(_ image: UIImage) -> String? {
        let fileName = "\(UUID().uuidString).jpg"
        let url = directory.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        do {
            try data.write(to: url)
            return fileName
        } catch {
            return nil
        }
    }

    static func load(_ fileName: String) -> UIImage? {
        let url = directory.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: url.path)
    }

    static func delete(_ fileName: String) {
        let url = directory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }
    
    
}
