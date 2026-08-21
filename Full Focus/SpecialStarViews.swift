//SpecialStarViews.swift
import SwiftUI

/// Disegno unico per ogni stella "speciale" (traguardo di striscia).
/// Tutto il movimento è ricavato da `time` con la trigonometria dentro
/// `Canvas`, non da animazioni SwiftUI per-istanza: così anche con
/// centinaia di stelle a schermo il costo resta un semplice calcolo,
/// non un motore di animazione per ognuna.
struct SpecialStarView: View {
    let starType: StarType
    let size: CGFloat
    let time: Double
    let phaseSeed: Double
    let isLatest: Bool

    private var phase: Double { time * 1.0 + phaseSeed }

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            switch starType {
            case .supernova: drawSupernova(context: context, center: center)
            case .pulsar: drawPulsar(context: context, center: center)
            case .magnetar: drawMagnetar(context: context, center: center)
            case .quasar: drawQuasar(context: context, center: center)
            case .blackHole: drawBlackHole(context: context, center: center)
            default: break
            }
        }
        .frame(width: size * 2.4, height: size * 2.4)
        .allowsHitTesting(false)
    }

    // MARK: - Supernova: nucleo bianco che "respira" con punte d'esplosione

    private func drawSupernova(context: GraphicsContext, center: CGPoint) {
        let breathe = (sin(phase * 2.6) + 1) / 2 // 0...1
        let spikeCount = 10
        let coreRadius = size * 0.32
        let spikeLength = size * (0.55 + breathe * 0.35)

        var burst = Path()
        for i in 0..<spikeCount {
            let angle = Double(i) / Double(spikeCount) * .pi * 2
            let inner = CGPoint(x: center.x + cos(angle) * coreRadius * 0.9,
                                 y: center.y + sin(angle) * coreRadius * 0.9)
            let outer = CGPoint(x: center.x + cos(angle) * spikeLength,
                                 y: center.y + sin(angle) * spikeLength)
            burst.move(to: inner)
            burst.addLine(to: outer)
        }
        context.stroke(burst, with: .color(.white.opacity(0.55 + breathe * 0.3)), lineWidth: 2)

        let glowRect = CGRect(x: center.x - coreRadius * 2.1, y: center.y - coreRadius * 2.1,
                               width: coreRadius * 4.2, height: coreRadius * 4.2)
        context.fill(Circle().path(in: glowRect), with: .color(.orange.opacity(0.18 + breathe * 0.12)))

        let coreRect = CGRect(x: center.x - coreRadius, y: center.y - coreRadius,
                               width: coreRadius * 2, height: coreRadius * 2)
        context.fill(Circle().path(in: coreRect), with: .color(.white))
    }

    // MARK: - Pulsar: nucleo minuscolo con due fasci di luce rotanti

    private func drawPulsar(context: GraphicsContext, center: CGPoint) {
        let coreRadius = size * 0.16
        let beamLength = size * 1.05
        let angle = phase * 2.4

        for direction: Double in [0, .pi] {
            let a = angle + direction
            let tip = CGPoint(x: center.x + cos(a) * beamLength, y: center.y + sin(a) * beamLength)
            let widthAngle = 0.16
            let left = CGPoint(x: center.x + cos(a - widthAngle) * coreRadius * 1.4,
                                y: center.y + sin(a - widthAngle) * coreRadius * 1.4)
            let right = CGPoint(x: center.x + cos(a + widthAngle) * coreRadius * 1.4,
                                 y: center.y + sin(a + widthAngle) * coreRadius * 1.4)
            var beam = Path()
            beam.move(to: left)
            beam.addLine(to: tip)
            beam.addLine(to: right)
            beam.closeSubpath()
            context.fill(beam, with: .linearGradient(
                Gradient(colors: [.mint.opacity(0.5), .mint.opacity(0)]),
                startPoint: center, endPoint: tip
            ))
        }

        let coreRect = CGRect(x: center.x - coreRadius, y: center.y - coreRadius,
                               width: coreRadius * 2, height: coreRadius * 2)
        context.fill(Circle().path(in: coreRect), with: .color(.mint))
        context.stroke(Circle().path(in: coreRect.insetBy(dx: -3, dy: -3)), with: .color(.mint.opacity(0.5)), lineWidth: 1.5)
    }

    // MARK: - Magnetar: nucleo viola avvolto da anelli di campo magnetico

    private func drawMagnetar(context: GraphicsContext, center: CGPoint) {
        let coreRadius = size * 0.26
        let loopWobble = sin(phase * 1.3) * 0.15

        for i in 0..<3 {
            let baseAngle = Double(i) * (.pi * 2 / 3) + phase * 0.35
            var loop = Path()
            let r = size * (0.5 + loopWobble)
            let a1 = CGPoint(x: center.x + cos(baseAngle) * coreRadius, y: center.y + sin(baseAngle) * coreRadius)
            let a2 = CGPoint(x: center.x + cos(baseAngle + .pi) * coreRadius, y: center.y + sin(baseAngle + .pi) * coreRadius)
            let control = CGPoint(x: center.x + cos(baseAngle + .pi / 2) * r, y: center.y + sin(baseAngle + .pi / 2) * r)
            loop.move(to: a1)
            loop.addQuadCurve(to: a2, control: control)
            context.stroke(loop, with: .color(.purple.opacity(0.55)), lineWidth: 1.6)
        }

        let coreRect = CGRect(x: center.x - coreRadius, y: center.y - coreRadius,
                               width: coreRadius * 2, height: coreRadius * 2)
        context.fill(Circle().path(in: coreRect), with: .color(.purple))
        context.fill(Circle().path(in: coreRect.insetBy(dx: coreRadius * 0.5, dy: coreRadius * 0.5)),
                     with: .color(.white.opacity(0.6)))
    }

    // MARK: - Quasar: disco d'accrescimento con due getti opposti

    private func drawQuasar(context: GraphicsContext, center: CGPoint) {
        let coreRadius = size * 0.22
        let jetLength = size * 1.15
        let tilt = 0.35

        var context = context

        var disk = Path(ellipseIn: CGRect(x: center.x - size * 0.65, y: center.y - size * 0.22,
                                           width: size * 1.3, height: size * 0.44))
        context.opacity = 0.5
        context.fill(disk, with: .linearGradient(
            Gradient(colors: [Color(red: 0.6, green: 0.4, blue: 1.0), .white.opacity(0.3)]),
            startPoint: CGPoint(x: center.x - size * 0.65, y: center.y),
            endPoint: CGPoint(x: center.x + size * 0.65, y: center.y)
        ))
        context.opacity = 1

        for direction: Double in [-1, 1] {
            var jet = Path()
            jet.move(to: center)
            jet.addLine(to: CGPoint(x: center.x + tilt * jetLength * direction * 0.3,
                                     y: center.y - jetLength * direction))
            context.stroke(jet, with: .linearGradient(
                Gradient(colors: [Color(red: 0.6, green: 0.4, blue: 1.0), .clear]),
                startPoint: center,
                endPoint: CGPoint(x: center.x, y: center.y - jetLength * direction)
            ), lineWidth: 3)
        }

        disk = Path(ellipseIn: CGRect(x: center.x - coreRadius, y: center.y - coreRadius,
                                       width: coreRadius * 2, height: coreRadius * 2))
        context.fill(disk, with: .color(.white))
    }

    // MARK: - Buco nero: orizzonte degli eventi con disco inclinato

    private func drawBlackHole(context: GraphicsContext, center: CGPoint) {
        let horizonRadius = size * 0.34
        let wobble = sin(phase * 1.1) * 0.05

        var diskPath = context
        diskPath.translateBy(x: center.x, y: center.y)
        diskPath.rotate(by: .radians(0.5))
        let diskRect = CGRect(x: -size * 0.75, y: -size * (0.16 + wobble),
                               width: size * 1.5, height: size * (0.32 + wobble * 2))
        diskPath.fill(Path(ellipseIn: diskRect), with: .linearGradient(
            Gradient(colors: [.purple.opacity(0.7), .white.opacity(0.4), .purple.opacity(0.7)]),
            startPoint: CGPoint(x: diskRect.minX, y: 0),
            endPoint: CGPoint(x: diskRect.maxX, y: 0)
        ))

        let horizonRect = CGRect(x: center.x - horizonRadius, y: center.y - horizonRadius,
                                  width: horizonRadius * 2, height: horizonRadius * 2)
        context.fill(Circle().path(in: horizonRect), with: .color(.black))
        context.stroke(Circle().path(in: horizonRect), with: .color(.purple.opacity(0.6)), lineWidth: 1.5)
    }
}
