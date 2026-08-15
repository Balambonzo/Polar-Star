import UIKit

/// Punto unico per tutti i feedback aptici dell'app — così restano
/// coerenti (stessa intensità per lo stesso tipo di azione) invece di
/// essere scritti a mano ogni volta con stili diversi.
enum Haptics {
    /// Tocco leggero: pausa, annulla, indietro, selezioni minori.
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    /// Azione principale: avvia un'attività, salva, conferma.
    static func action() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    /// Cambio di selezione (es. scelta di una zona muscolare).
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
