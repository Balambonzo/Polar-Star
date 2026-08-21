import Foundation
import SwiftUI

/// Il tipo di stella mostrato in Collezione per un giorno completato.
/// Le stelle "ordinarie" dipendono da quanto hai studiato quel giorno;
/// le "speciali" sostituiscono quella ordinaria nei giorni che segnano
/// un traguardo della striscia consecutiva.
enum StarType: Equatable {
    case redDwarf
    case yellowDwarf
    case redGiant
    case blueGiant
    case supergiant
    case hypergiant
    case supernova
    case pulsar
    case magnetar
    case quasar
    case blackHole
    case whiteHole

    var displayName: String {
        switch self {
        case .redDwarf: return "Nana Rossa"
        case .yellowDwarf: return "Nana Gialla"
        case .redGiant: return "Gigante Rossa"
        case .blueGiant: return "Gigante Blu"
        case .supergiant: return "Supergigante"
        case .hypergiant: return "Ipergigante"
        case .supernova: return "Supernova"
        case .pulsar: return "Pulsar"
        case .magnetar: return "Magnetar"
        case .quasar: return "Quasar"
        case .blackHole: return "Buco Nero"
        case .whiteHole: return "Buco Bianco"
        }
    }

    var baseSize: CGFloat {
        switch self {
        case .redDwarf: return 22
        case .yellowDwarf: return 28
        case .redGiant: return 34
        case .blueGiant: return 38
        case .supergiant: return 44
        case .hypergiant: return 50
        case .supernova: return 46
        case .pulsar: return 40
        case .magnetar: return 42
        case .quasar: return 48
        case .blackHole: return 56
        case .whiteHole: return 62
        }
    }

    var coreColor: Color {
        switch self {
        case .redDwarf: return .red
        case .yellowDwarf: return .yellow
        case .redGiant: return .orange
        case .blueGiant: return .cyan
        case .supergiant: return .blue
        case .hypergiant: return Color(red: 0.7, green: 0.85, blue: 1.0)
        case .supernova: return .white
        case .pulsar: return .mint
        case .magnetar: return .purple
        case .quasar: return Color(red: 0.6, green: 0.4, blue: 1.0)
        case .blackHole: return .black
        case .whiteHole: return .white
        }
    }

    var glowColor: Color {
        starType_glowOverride ?? coreColor
    }

    /// Le stelle di traguardo hanno un disegno dedicato (vedi
    /// SpecialStarShapeView) invece del semplice cerchio colorato.
    var isSpecial: Bool {
        switch self {
        case .supernova, .pulsar, .magnetar, .quasar, .blackHole, .whiteHole: return true
        default: return false
        }
    }

    private var starType_glowOverride: Color? {
        switch self {
        case .blackHole: return .purple
        case .whiteHole: return .yellow
        default: return nil
        }
    }

    /// Stella ordinaria, in base a quanti minuti hai studiato quel giorno.
    static func forDuration(minutes: Int) -> StarType {
        switch minutes {
        case ..<30: return .redDwarf
        case 30..<60: return .yellowDwarf
        case 60..<90: return .redGiant
        case 90..<120: return .blueGiant
        case 120..<150: return .supergiant
        default: return .hypergiant
        }
    }

    /// Stella speciale se quel giorno è un traguardo della striscia
    /// consecutiva, altrimenti nil (si usa quella ordinaria).
    static func milestone(forStreakPosition position: Int) -> StarType? {
        guard position > 0 else { return nil }

        if position % 365 == 0 { return .whiteHole }

        let withinCycle = position % 365
        if withinCycle > 0 && withinCycle % 100 == 0 { return .blackHole }

        switch withinCycle {
        case 10: return .supernova
        case 30: return .pulsar
        case 50: return .magnetar
        case 75: return .quasar
        default: return nil
        }
    }
}
