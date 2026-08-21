//ConstellationPatterns.swift
import Foundation
import CoreGraphics

/// Una costellazione predefinita: la forma che assumono (al massimo) 6 stelle
/// quando vengono raggruppate insieme.
///
/// A differenza della versione precedente, i punti NON sono normalizzati in
/// un quadrato 0...1: sono in "unità di cielo" libere, centrate attorno
/// all'origine (0,0), con un'estensione e un rapporto larghezza/altezza che
/// varia da costellazione a costellazione — proprio come nel cielo vero,
/// dove Orione è alto e stretto, Cassiopea è larga e bassa, Delfino è
/// piccola e compatta, Scorpione è una lunga curva.
///
/// L'ordine dei punti è l'ordine cronologico delle stelle: il collegamento
/// i -> i+1 disegna la "linea" della costellazione, e ricalca (in forma
/// stilizzata) la sagoma reale della costellazione.
struct ConstellationPattern {
    let name: String
    let points: [CGPoint] // sempre 6 punti
}

enum ConstellationPatterns {

    /// 25 costellazioni reali, stilizzate a 6 punti ciascuna, disegnate a
    /// mano per essere riconoscibili: niente quadrati, niente coordinate
    /// casuali. Ogni forma ha la sua estensione ed inclinazione naturale.
    static let all: [ConstellationPattern] = [

        // Grande Carro: manico lungo + secchio, in diagonale.
        ConstellationPattern(name: "Orsa Maggiore", points: [
            CGPoint(x: -1.60, y: -0.90), CGPoint(x: -0.95, y: -0.55),
            CGPoint(x: -0.35, y: -0.25), CGPoint(x: -0.35, y: 0.35),
            CGPoint(x: 0.55, y: 0.15), CGPoint(x: 0.65, y: -0.55)
        ]),

        // Spalle in alto, cintura al centro, piede in basso: alta e stretta.
        ConstellationPattern(name: "Orione", points: [
            CGPoint(x: -0.65, y: -1.20), CGPoint(x: 0.70, y: -1.15),
            CGPoint(x: 0.30, y: 0.00), CGPoint(x: 0.00, y: 0.05),
            CGPoint(x: -0.30, y: 0.10), CGPoint(x: -0.15, y: 1.30)
        ]),

        // La "W": larga, bassa, a zig-zag.
        ConstellationPattern(name: "Cassiopea", points: [
            CGPoint(x: -1.50, y: 0.25), CGPoint(x: -0.80, y: -0.50),
            CGPoint(x: -0.10, y: 0.15), CGPoint(x: 0.60, y: -0.55),
            CGPoint(x: 1.30, y: 0.05), CGPoint(x: 1.60, y: 0.60)
        ]),

        // Chele in alto, corpo, coda arricciata: lunga curva diagonale.
        ConstellationPattern(name: "Scorpione", points: [
            CGPoint(x: -1.60, y: -0.90), CGPoint(x: -1.00, y: -0.30),
            CGPoint(x: -0.30, y: 0.10), CGPoint(x: 0.40, y: 0.50),
            CGPoint(x: 1.00, y: 0.90), CGPoint(x: 1.30, y: 0.30)
        ]),

        // Croce del Nord: asse verticale lungo, ali corte.
        ConstellationPattern(name: "Cigno", points: [
            CGPoint(x: 0.00, y: -1.50), CGPoint(x: 0.00, y: -0.50),
            CGPoint(x: -1.10, y: 0.15), CGPoint(x: 1.10, y: 0.15),
            CGPoint(x: 0.00, y: 0.40), CGPoint(x: 0.00, y: 1.40)
        ]),

        // Falce (testa) + triangolo (corpo/coda): allungata in orizzontale.
        ConstellationPattern(name: "Leone", points: [
            CGPoint(x: -1.60, y: 0.10), CGPoint(x: -0.75, y: -0.15),
            CGPoint(x: -0.10, y: -0.15), CGPoint(x: 0.35, y: -0.55),
            CGPoint(x: 0.85, y: -0.15), CGPoint(x: 0.55, y: 0.35)
        ]),

        // Croce piccola e compatta, con due stelle guida accanto.
        ConstellationPattern(name: "Croce del Sud", points: [
            CGPoint(x: 0.00, y: -1.10), CGPoint(x: 0.05, y: -0.20),
            CGPoint(x: 0.00, y: 0.85), CGPoint(x: -0.80, y: 0.20),
            CGPoint(x: 0.85, y: 0.05), CGPoint(x: 0.50, y: 1.10)
        ]),

        // Parallelogramma piccolo con Vega in punta: compatta.
        ConstellationPattern(name: "Lira", points: [
            CGPoint(x: 0.00, y: -1.20), CGPoint(x: -0.40, y: -0.30),
            CGPoint(x: -0.55, y: 0.65), CGPoint(x: 0.15, y: 0.85),
            CGPoint(x: 0.50, y: 0.15), CGPoint(x: 0.35, y: -0.35)
        ]),

        // Lunga catena serpeggiante a S: molto allungata.
        ConstellationPattern(name: "Drago", points: [
            CGPoint(x: -1.70, y: -0.60), CGPoint(x: -1.00, y: -0.90),
            CGPoint(x: -0.30, y: -0.50), CGPoint(x: 0.30, y: 0.10),
            CGPoint(x: 0.90, y: 0.70), CGPoint(x: 1.60, y: 0.40)
        ]),

        // Piccolo Carro: manico + secchio, compatto e con inclinazione diversa dal Grande Carro.
        ConstellationPattern(name: "Orsa Minore", points: [
            CGPoint(x: -1.10, y: -0.70), CGPoint(x: -0.50, y: -0.90),
            CGPoint(x: 0.10, y: -0.60), CGPoint(x: 0.15, y: 0.15),
            CGPoint(x: 0.75, y: 0.35), CGPoint(x: 0.55, y: -0.25)
        ]),

        // Grande Quadrato + collo: blocco largo con un'appendice.
        ConstellationPattern(name: "Pegaso", points: [
            CGPoint(x: -0.90, y: -0.70), CGPoint(x: 0.90, y: -0.75),
            CGPoint(x: 0.85, y: 0.75), CGPoint(x: -0.95, y: 0.80),
            CGPoint(x: -1.50, y: 1.30), CGPoint(x: -1.90, y: 1.75)
        ]),

        // Catena diagonale lunga e piatta.
        ConstellationPattern(name: "Andromeda", points: [
            CGPoint(x: -1.60, y: -0.30), CGPoint(x: -0.90, y: -0.05),
            CGPoint(x: -0.15, y: 0.15), CGPoint(x: 0.55, y: 0.45),
            CGPoint(x: 1.20, y: 0.55), CGPoint(x: 1.70, y: 0.90)
        ]),

        // Catena diagonale con una piega netta: più ripida di Andromeda.
        ConstellationPattern(name: "Perseo", points: [
            CGPoint(x: -1.50, y: 1.10), CGPoint(x: -0.85, y: 0.55),
            CGPoint(x: -0.20, y: 0.05), CGPoint(x: 0.15, y: -0.55),
            CGPoint(x: 0.75, y: -0.35), CGPoint(x: 1.40, y: -0.90)
        ]),

        // Pentagono con Capella al centro dell'apertura: verticale.
        ConstellationPattern(name: "Auriga", points: [
            CGPoint(x: 0.00, y: -1.30), CGPoint(x: 0.95, y: -0.35),
            CGPoint(x: 0.55, y: 0.90), CGPoint(x: -0.55, y: 0.90),
            CGPoint(x: -0.95, y: -0.35), CGPoint(x: 0.00, y: -0.10)
        ]),

        // Due colonne quasi parallele (i gemelli), larga e alta.
        ConstellationPattern(name: "Gemelli", points: [
            CGPoint(x: -0.90, y: -1.30), CGPoint(x: -0.75, y: 0.00),
            CGPoint(x: -0.55, y: 1.30), CGPoint(x: 0.90, y: -1.20),
            CGPoint(x: 0.70, y: 0.05), CGPoint(x: 0.50, y: 1.25)
        ]),

        // V (Iadi) con un lungo corno verso l'alto: molto allungata.
        ConstellationPattern(name: "Toro", points: [
            CGPoint(x: -1.40, y: -0.20), CGPoint(x: -0.60, y: 0.15),
            CGPoint(x: 0.00, y: 0.55), CGPoint(x: 0.55, y: 0.10),
            CGPoint(x: 1.30, y: -0.85), CGPoint(x: -0.20, y: -1.30)
        ]),

        // Teiera: esagono compatto, leggermente più largo che alto.
        ConstellationPattern(name: "Sagittario", points: [
            CGPoint(x: -1.10, y: -0.35), CGPoint(x: -0.55, y: -0.85),
            CGPoint(x: 0.35, y: -0.75), CGPoint(x: 0.95, y: -0.15),
            CGPoint(x: 0.65, y: 0.55), CGPoint(x: -0.65, y: 0.55)
        ]),

        // Ali spiegate attorno ad Altair: molto larga e bassa.
        ConstellationPattern(name: "Aquila", points: [
            CGPoint(x: -1.50, y: 0.05), CGPoint(x: -0.50, y: -0.15),
            CGPoint(x: 0.00, y: 0.00), CGPoint(x: 0.50, y: 0.15),
            CGPoint(x: 1.50, y: 0.25), CGPoint(x: 0.00, y: 0.95)
        ]),

        // Arco/semicerchio aperto: compatta e arrotondata.
        ConstellationPattern(name: "Corona Boreale", points: [
            CGPoint(x: -1.00, y: 0.35), CGPoint(x: -0.55, y: -0.35),
            CGPoint(x: 0.00, y: -0.60), CGPoint(x: 0.55, y: -0.35),
            CGPoint(x: 1.00, y: 0.35), CGPoint(x: 0.50, y: 0.70)
        ]),

        // Trapezio (keystone) con due arti che si allungano in diagonale.
        ConstellationPattern(name: "Ercole", points: [
            CGPoint(x: -0.75, y: -0.80), CGPoint(x: 0.75, y: -0.70),
            CGPoint(x: 0.55, y: 0.65), CGPoint(x: -0.60, y: 0.75),
            CGPoint(x: -1.50, y: 1.40), CGPoint(x: 1.40, y: -1.40)
        ]),

        // Piccolo uncino curvo: corta e compatta.
        ConstellationPattern(name: "Ariete", points: [
            CGPoint(x: -1.20, y: -0.30), CGPoint(x: -0.50, y: -0.55),
            CGPoint(x: 0.05, y: -0.25), CGPoint(x: 0.50, y: 0.25),
            CGPoint(x: 0.15, y: 0.05), CGPoint(x: -0.60, y: -0.10)
        ]),

        // Sagoma a "barca": larga e bassa, come una V molto aperta.
        ConstellationPattern(name: "Capricorno", points: [
            CGPoint(x: -1.60, y: -0.15), CGPoint(x: -0.80, y: 0.35),
            CGPoint(x: 0.00, y: 0.55), CGPoint(x: 0.80, y: 0.30),
            CGPoint(x: 1.50, y: -0.20), CGPoint(x: 0.10, y: 0.10)
        ]),

        // Catena diagonale lunga con un ramo laterale (i due pesci legati dal filo).
        ConstellationPattern(name: "Pesci", points: [
            CGPoint(x: -1.70, y: -0.90), CGPoint(x: -0.70, y: -0.30),
            CGPoint(x: 0.00, y: 0.00), CGPoint(x: 0.70, y: 0.50),
            CGPoint(x: 1.60, y: 1.10), CGPoint(x: 0.00, y: -1.20)
        ]),

        // Piccolo aquilone con una coda: costellazione minuscola.
        ConstellationPattern(name: "Delfino", points: [
            CGPoint(x: -0.30, y: -0.55), CGPoint(x: 0.35, y: -0.65),
            CGPoint(x: 0.55, y: 0.05), CGPoint(x: 0.00, y: 0.40),
            CGPoint(x: -0.45, y: 0.05), CGPoint(x: -0.90, y: 0.90)
        ]),

        // Freccia sottile e allungata in diagonale, con la cocca a lato.
        ConstellationPattern(name: "Freccia", points: [
            CGPoint(x: -1.10, y: 0.55), CGPoint(x: -0.55, y: 0.25),
            CGPoint(x: 0.00, y: 0.00), CGPoint(x: 0.55, y: -0.25),
            CGPoint(x: 1.10, y: -0.55), CGPoint(x: 0.65, y: 0.05)
        ])
    ]

    /// Ogni forma base ha 4 orientamenti discreti (originale, specchio
    /// orizzontale, specchio verticale, rotazione 180°): 25 × 4 = 100
    /// combinazioni, sufficienti a coprire 100 × 6 = 600 stelle senza mai
    /// ripetere la stessa forma nello stesso orientamento.
    private static let orientationsPerPattern = 4

    /// Sceglie forma, orientamento, rotazione libera e scala per l'N-esima
    /// costellazione della cronologia. Tutto dipende solo da `index`:
    /// deterministico, stesso indice → sempre lo stesso identico risultato.
    static func pattern(forConstellationIndex index: Int) -> ConstellationPattern {
        let totalCombos = all.count * orientationsPerPattern
        let shift = Int(DeterministicRandom.value(seed: index * 7 + 3) * Double(totalCombos))
        let combined = ((index + shift) % totalCombos + totalCombos) % totalCombos
        let baseIndex = combined / orientationsPerPattern
        let orientation = combined % orientationsPerPattern

        var points = applyOrientation(orientation, to: all[baseIndex].points)

        // Rotazione libera deterministica tra -20° e +20°: rompe la
        // rigidità degli orientamenti "netti" dati dai mirror, così ogni
        // costellazione sembra leggermente storta nel cielo, come in natura.
        let rotationSeed = index * 13 + 91
        let rotationDegrees = (DeterministicRandom.value(seed: rotationSeed) * 40.0) - 20.0
        let rotationRadians = rotationDegrees * .pi / 180
        points = points.map { rotatePoint($0, byRadians: rotationRadians) }

        // Scala deterministica tra 0.85 e 1.25: dà l'illusione di
        // profondità, come se alcune costellazioni fossero più vicine
        // (più grandi) e altre più lontane (più piccole).
        let scaleSeed = index * 29 + 17
        let scale = 0.85 + DeterministicRandom.value(seed: scaleSeed) * (1.25 - 0.85)
        points = points.map { CGPoint(x: $0.x * scale, y: $0.y * scale) }

        return ConstellationPattern(name: all[baseIndex].name, points: points)
    }

    private static func applyOrientation(_ orientation: Int, to points: [CGPoint]) -> [CGPoint] {
        switch orientation {
        case 1: // specchio orizzontale
            return points.map { CGPoint(x: -$0.x, y: $0.y) }
        case 2: // specchio verticale
            return points.map { CGPoint(x: $0.x, y: -$0.y) }
        case 3: // rotazione di 180°
            return points.map { CGPoint(x: -$0.x, y: -$0.y) }
        default: // originale
            return points
        }
    }

    private static func rotatePoint(_ point: CGPoint, byRadians angle: Double) -> CGPoint {
        let cosA = CGFloat(cos(angle))
        let sinA = CGFloat(sin(angle))
        return CGPoint(
            x: point.x * cosA - point.y * sinA,
            y: point.x * sinA + point.y * cosA
        )
    }
}

/// Generatore pseudo-casuale deterministico (stesso seed → stesso output),
/// usato per introdurre variazione visiva senza far "ballare" il layout tra
/// un render e l'altro.
enum DeterministicRandom {
    static func value(seed: Int) -> Double {
        let x = sin(Double(seed) * 12.9898) * 43758.5453
        return x - floor(x)
    }
}
