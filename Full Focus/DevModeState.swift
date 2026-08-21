import Foundation
import Observation

/// Stato condiviso "modalità sviluppatore": quando attivo, alcune
/// schermate mostrano numeri finti (streak a 100 ecc.) per fare
/// screenshot o testare l'interfaccia senza accumulare giorni veri.
/// NON tocca mai i dati reali salvati in SwiftData/PocketBase — è
/// solo un override visivo, temporaneo, che si resetta riavviando l'app.
@Observable
final class DevModeState {
    static let shared = DevModeState()
    private init() {}

    var isActive = false
}
