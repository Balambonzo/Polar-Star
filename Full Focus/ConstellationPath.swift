import Foundation
import CoreGraphics

/// Calcola le posizioni (x,y) di ogni giorno lungo un sentiero serpeggiante,
/// così che la collezione si legga come un percorso nel tempo e non come
/// una griglia. Il percorso avanza a "onda": scende leggermente verso
/// destra, poi verso sinistra, come un tratturo in salita.
enum ConstellationPath {

    struct Point {
        let x: CGFloat   // 0...1, frazione della larghezza disponibile
        let y: CGFloat   // offset verticale in punti (cresce sempre)
    }

    static let verticalSpacing: CGFloat = 92
    static let horizontalAmplitude: CGFloat = 0.72 // quanto si allarga l'onda (0...1)

    /// Una posizione per ogni indice di giorno, dal più vecchio (0) al più recente.
    static func points(count: Int) -> [Point] {
        guard count > 0 else { return [] }
        var result: [Point] = []
        for i in 0..<count {
            let wave = sin(Double(i) * 0.7) // oscillazione morbida
            let center = 0.5
            let x = center + wave * Double(horizontalAmplitude) / 2
            let y = CGFloat(i) * verticalSpacing
            result.append(Point(x: CGFloat(x), y: y))
        }
        return result
    }
}
