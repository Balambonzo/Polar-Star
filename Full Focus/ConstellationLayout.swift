//ConstellationLayout.swift
import Foundation
import CoreGraphics

/// Una singola stella posizionata in coordinate assolute, LOCALI alla
/// galassia a cui appartiene (origine 0,0 in alto a sinistra della galassia).
///
/// NON MODIFICATA: stessa API di prima, così ConstellationView e
/// GalaxyFlowView continuano a funzionare senza alcuna modifica.
struct StarPosition: Identifiable {
    let day: DayInfo
    let x: CGFloat
    let y: CGFloat
    var id: Date { day.date }
}

/// Un gruppo di (al più) 6 costellazioni — al più 36 stelle — che formano
/// una galassia. È l'unità di virtualizzazione (una cella della LazyVStack),
/// ma NON ha alcun contenitore visivo: nessun bordo, nessuno sfondo.
///
/// NON MODIFICATA: stessa API di prima.
struct GalaxyGroup: Identifiable {
    let id = UUID()
    let stars: [StarPosition]
    let connections: [(Int, Int)]   // indici in `stars`, catena continua interna
    let size: CGSize                // frame necessario a contenere questa galassia
    let extraGapBefore: CGFloat     // spazio in più prima di questa galassia (streak interrotto)
}

/// Trasforma la cronologia piatta dei giorni in un'unica sequenza verticale
/// di galassie.
///
/// Rispetto alla versione precedente, le costellazioni non scendono più in
/// colonna con un'oscillazione sinusoidale: dentro ogni galassia vengono
/// disposte come un vero ammasso stellare, usando come "scheletro" del
/// cluster una delle forme organiche già presenti in
/// `ConstellationShapeLibrary` (esagono, arco, spirale, ventaglio, onda...),
/// ruotata e con un piccolo jitter deterministico per costellazione — così
/// il risultato non sembra mai un poligono rigido, ma un gruppo naturale di
/// stelle. La scelta è volutamente deterministica e precalcolata (niente
/// Poisson-disk o simulazioni a runtime): stesso indice di galassia → stesso
/// identico cluster ad ogni avvio, e nessun calcolo geometrico pesante
/// durante il rendering.
enum ConstellationLayout {

    private static let starsPerConstellation = 6
    private static let constellationsPerGalaxy = 6

    /// Pixel per "unità di cielo" di una singola costellazione (vedi
    /// `ConstellationPatterns`, i cui punti sono centrati sull'origine).
    private static let constellationScale: CGFloat = 24

    /// Raggio (in punti) usato per scalare lo "scheletro" del cluster
    /// (`ConstellationShapeLibrary`, punti di modulo ~1) attorno al centro
    /// della galassia: distanza tipica tra i centri di due costellazioni
    /// vicine nello stesso ammasso.
    private static let clusterRadius: CGFloat = 92

    /// Piccolo spostamento casuale deterministico applicato al centro di
    /// ogni costellazione, per rompere la regolarità geometrica dello
    /// scheletro e dare un aspetto più naturale, "da cielo vero".
    private static let clusterJitter: CGFloat = 14

    /// Margine attorno al bounding box effettivo delle stelle, per non far
    /// toccare gli aloni delle stelle il bordo del frame della galassia.
    private static let canvasPadding: CGFloat = 56

    private static let interRunGapUnit: CGFloat = 9
    private static let interRunGapMax: CGFloat = 240

    static func buildGalaxies(from days: [DayInfo]) -> [GalaxyGroup] {
        guard !days.isEmpty else { return [] }

        // 1. Spezza in "run": sequenze di giorni completati/in corso separate
        //    da almeno un giorno saltato. Un giorno saltato non genera mai
        //    una stella, interrompe solo il filo cronologico.
        var runs: [[DayInfo]] = []
        var current: [DayInfo] = []
        for day in days {
            switch day.status {
            case .completed, .todayPending:
                current.append(day)
            case .missed:
                if !current.isEmpty { runs.append(current); current = [] }
            }
        }
        if !current.isEmpty { runs.append(current) }

        // Quanti giorni saltati precedono ogni run, per dosare lo spazio vuoto.
        var gapBeforeRun = Array(repeating: 0, count: runs.count)
        var scanIndex = 0
        for (i, run) in runs.enumerated() {
            if let firstDate = run.first?.date, let idx = days.firstIndex(where: { $0.date == firstDate }) {
                gapBeforeRun[i] = max(0, idx - scanIndex)
                scanIndex = idx + run.count
            }
        }

        var galaxies: [GalaxyGroup] = []
        var globalConstellationIndex = 0
        var globalGalaxyIndex = 0

        for (runIndex, run) in runs.enumerated() {
            // 2. Ogni run si spezza in costellazioni da (al più) 6 giorni...
            let constellationChunks = run.chunked(into: starsPerConstellation)
            // 3. ...e le costellazioni si raggruppano in galassie da (al più) 6.
            let galaxyChunks = constellationChunks.chunked(into: constellationsPerGalaxy)

            for (galaxyIndexInRun, galaxyChunk) in galaxyChunks.enumerated() {
                // Centro (relativo, non ancora traslato) di ogni costellazione
                // dentro questa galassia: un ammasso organico, non una griglia.
                let centers = clusterCenters(forGalaxyIndex: globalGalaxyIndex, count: galaxyChunk.count)

                // Stelle "grezze", in coordinate libere (possono essere
                // negative): le traslo in coordinate positive solo alla fine,
                // una volta noto il bounding box reale della galassia.
                var rawStars: [(day: DayInfo, x: CGFloat, y: CGFloat)] = []
                var connections: [(Int, Int)] = []

                for (cIndex, chunkDays) in galaxyChunk.enumerated() {
                    let pattern = ConstellationPatterns.pattern(forConstellationIndex: globalConstellationIndex)
                    globalConstellationIndex += 1

                    let center = centers[cIndex]

                    for (i, day) in chunkDays.enumerated() {
                        let unit = pattern.points[i]
                        let x = center.x + unit.x * constellationScale
                        let y = center.y + unit.y * constellationScale

                        let idx = rawStars.count
                        rawStars.append((day: day, x: x, y: y))
                        // Il filo collega solo le stelle DENTRO la stessa
                        // costellazione (i > 0, cioè non è la prima stella del
                        // gruppo): niente linea tra l'ultima stella di una
                        // costellazione e la prima di quella successiva, e
                        // ovviamente niente linea tra una galassia e l'altra.
                        // Ogni costellazione resta un disegno isolato, come
                        // nel cielo vero.
                        if i > 0 { connections.append((idx - 1, idx)) }
                    }
                }

                // Bounding box reale delle stelle di questa galassia: la
                // dimensione del frame si adatta al cluster invece di usare
                // una larghezza fissa, così ogni ammasso occupa esattamente
                // lo spazio di cui ha bisogno, né più né meno.
                let minX = rawStars.map(\.x).min() ?? 0
                let maxX = rawStars.map(\.x).max() ?? 0
                let minY = rawStars.map(\.y).min() ?? 0
                let maxY = rawStars.map(\.y).max() ?? 0

                let offsetX = -minX + canvasPadding
                let offsetY = -minY + canvasPadding

                let stars = rawStars.map {
                    StarPosition(day: $0.day, x: $0.x + offsetX, y: $0.y + offsetY)
                }

                let size = CGSize(
                    width: (maxX - minX) + canvasPadding * 2,
                    height: (maxY - minY) + canvasPadding * 2
                )

                let isFirstGalaxyOfRun = galaxyIndexInRun == 0
                let extraGap: CGFloat = (isFirstGalaxyOfRun && runIndex > 0)
                    ? min(CGFloat(gapBeforeRun[runIndex]) * interRunGapUnit, interRunGapMax)
                    : 0

                galaxies.append(
                    GalaxyGroup(stars: stars, connections: connections, size: size, extraGapBefore: extraGap)
                )
                globalGalaxyIndex += 1
            }
        }

        return galaxies
    }

    /// Calcola i centri (relativi, non ancora traslati) delle costellazioni
    /// dentro una galassia, disponendole come un ammasso organico invece che
    /// in griglia o in colonna.
    ///
    /// Riusa una delle forme già definite in `ConstellationShapeLibrary`
    /// come "scheletro" del cluster (i suoi 6 punti hanno modulo ~1, pensati
    /// esattamente per disporre 6 elementi in modo naturale), la ruota di un
    /// angolo deterministico diverso per ogni galassia — così due galassie
    /// consecutive non sembrano mai stampate con lo stesso stampino — e
    /// aggiunge un piccolo jitter deterministico per costellazione, per
    /// evitare che il cluster sembri un poligono perfetto.
    private static func clusterCenters(forGalaxyIndex galaxyIndex: Int, count: Int) -> [CGPoint] {
        guard count > 0 else { return [] }

        let shape = ConstellationShapeLibrary.shape(forIndex: galaxyIndex)

        let rotationSeed = galaxyIndex * 17 + 5
        let rotationAngle = DeterministicRandom.value(seed: rotationSeed) * 2 * Double.pi
        let cosA = CGFloat(cos(rotationAngle))
        let sinA = CGFloat(sin(rotationAngle))

        var centers: [CGPoint] = []
        for i in 0..<count {
            let base = shape.points[i % shape.points.count]

            // Ruota il punto base dello scheletro attorno al centro galassia.
            let rotatedX = base.x * cosA - base.y * sinA
            let rotatedY = base.x * sinA + base.y * cosA

            // Jitter deterministico, unico per ogni combinazione galassia+slot.
            let jitterSeedX = galaxyIndex * 101 + i * 7 + 3
            let jitterSeedY = galaxyIndex * 131 + i * 11 + 9
            let jitterX = (CGFloat(DeterministicRandom.value(seed: jitterSeedX)) - 0.5) * 2 * clusterJitter
            let jitterY = (CGFloat(DeterministicRandom.value(seed: jitterSeedY)) - 0.5) * 2 * clusterJitter

            centers.append(
                CGPoint(
                    x: rotatedX * clusterRadius + jitterX,
                    y: rotatedY * clusterRadius + jitterY
                )
            )
        }
        return centers
    }
}

extension Array {
    /// Divide l'array in blocchi da al più `size` elementi ciascuno.
    /// Nota: se il progetto ha già un'estensione con lo stesso nome altrove,
    /// rimuovi questa per evitare una doppia dichiarazione.
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0, !isEmpty else { return [] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
