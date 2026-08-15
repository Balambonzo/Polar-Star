import Foundation
import CoreGraphics

struct StarPosition: Identifiable {
    let day: DayInfo
    let x: CGFloat
    let y: CGFloat
    var id: Date { day.date }
}

struct ConstellationLayoutResult {
    let stars: [StarPosition]
    let connections: [(Int, Int)]
    let contentSize: CGSize
    let latestStarIndex: Int?
}

/// Trasforma la cronologia in una disposizione 2D: ogni striscia di giorni
/// consecutivi diventa un ammasso a spirale, separato dal successivo da
/// uno spazio proporzionale a quanto tempo è passato in mezzo.
enum ConstellationLayout {

    static func compute(days: [DayInfo]) -> ConstellationLayoutResult {
        guard !days.isEmpty else {
            return ConstellationLayoutResult(stars: [], connections: [], contentSize: CGSize(width: 400, height: 400), latestStarIndex: nil)
        }

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

        var gapBeforeRun = Array(repeating: 0, count: runs.count)
        var scanIndex = 0
        for (i, run) in runs.enumerated() {
            if let firstDate = run.first?.date, let idx = days.firstIndex(where: { $0.date == firstDate }) {
                gapBeforeRun[i] = max(0, idx - scanIndex)
                scanIndex = idx + run.count
            }
        }

        let goldenAngle = 2.399963
        let baseRadius: CGFloat = 26
        let baseSpacing: CGFloat = 150
        let gapUnit: CGFloat = 6
        let maxGapBonus: CGFloat = 240
        let jitterAmplitude: CGFloat = 90
        let canvasWidth: CGFloat = 340

        var stars: [StarPosition] = []
        var connections: [(Int, Int)] = []
        var centroidY: CGFloat = 90

        for (runIndex, run) in runs.enumerated() {
            if runIndex > 0 {
                centroidY += baseSpacing + min(CGFloat(gapBeforeRun[runIndex]) * gapUnit, maxGapBonus)
            }
            let centroidX = canvasWidth / 2 + CGFloat(sin(Double(runIndex) * 1.7)) * jitterAmplitude

            var runMaxY = centroidY
            for (i, day) in run.enumerated() {
                let angle = Double(i) * goldenAngle
                let radius = baseRadius * sqrt(Double(i) + 1)
                let x = centroidX + CGFloat(cos(angle)) * radius
                let y = centroidY + CGFloat(sin(angle)) * radius
                let starIndex = stars.count
                stars.append(StarPosition(day: day, x: x, y: y))
                if i > 0 { connections.append((starIndex - 1, starIndex)) }
                runMaxY = max(runMaxY, y)
            }
            centroidY = runMaxY
        }

        let rawMinX = stars.map(\.x).min() ?? 0
        if rawMinX < 40 {
            let shift = 40 - rawMinX
            stars = stars.map { StarPosition(day: $0.day, x: $0.x + shift, y: $0.y) }
        }

        let maxX = stars.map(\.x).max() ?? canvasWidth
        let contentWidth = max(canvasWidth, maxX + 80)
        let contentHeight = centroidY + 220

        return ConstellationLayoutResult(
            stars: stars,
            connections: connections,
            contentSize: CGSize(width: contentWidth, height: contentHeight),
            latestStarIndex: stars.indices.last
        )
    }
}
