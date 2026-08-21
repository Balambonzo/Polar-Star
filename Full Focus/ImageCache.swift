import UIKit

/// Cache in memoria per le foto associate ai giorni completati. Senza questa
/// cache, ogni volta che la vista si ridisegna (es. durante lo scroll)
/// `ImageStore.load` ridecodifica l'immagine da disco da zero — con molte
/// foto è uno dei costi nascosti più facili da dimenticare.
final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 300
    }

    func image(named fileName: String) -> UIImage? {
        let key = fileName as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        guard let loaded = ImageStore.load(fileName) else { return nil }
        cache.setObject(loaded, forKey: key)
        return loaded
    }
}
