import SwiftUI
/// Disegno dedicato per le stelle "speciali" (traguardi di streak): ognuna ha
/// una silhouette E un'animazione proprie, mai condivise con le altre.
/// Usata solo per le 6 varianti speciali: essendo rare, possiamo permetterci
/// dettagli e animazioni che non useremmo mai su centinaia di stelle normali.
struct SpecialStarShapeView: View {
    let type: StarType
    let size: CGFloat
    let animate: Bool

    var body: some View {
        switch type {
        case .supernova:
            SupernovaMark(size: size, color: type.coreColor, animate: animate)
        case .pulsar:
            PulsarMark(size: size, color: type.coreColor, spin: animate)
        case .magnetar:
            MagnetarMark(size: size, color: type.coreColor, pulse: animate)
        case .quasar:
            QuasarMark(size: size, color: type.coreColor, animate: animate)
        case .blackHole:
            BlackHoleMark(size: size, animate: animate)
        case .whiteHole:
            WhiteHoleMark(size: size, animate: animate)
        default:
            EmptyView()
        }
    }
}

// MARK: - Supernova (10 giorni): onda d'urto che si espande + nucleo che pulsa
// Solo movimento radiale (espansione/contrazione dal centro), niente
// spostamento laterale.

private struct SupernovaMark: View {
    let size: CGFloat
    let color: Color
    let animate: Bool

    @State private var shockwaveOut = false
    @State private var corePulse = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(shockwaveOut ? 0 : 0.6), lineWidth: 2)
                .frame(
                    width: size * (shockwaveOut ? 1.7 : 0.85),
                    height: size * (shockwaveOut ? 1.7 : 0.85)
                )

            Circle()
                .stroke(color.opacity(shockwaveOut ? 0 : 0.35), lineWidth: 1.4)
                .frame(
                    width: size * (shockwaveOut ? 1.35 : 0.7),
                    height: size * (shockwaveOut ? 1.35 : 0.7)
                )

            BurstShape(points: 10, innerRatio: 0.34)
                .fill(
                    RadialGradient(colors: [.white, color, color.opacity(0)], center: .center, startRadius: 0, endRadius: size / 2)
                )
                .frame(width: size, height: size)
                .scaleEffect(corePulse ? 1.07 : 0.95)

            Circle()
                .fill(Color.white)
                .frame(width: size * 0.22, height: size * 0.22)
                .shadow(color: .white.opacity(0.85), radius: 4)
                .scaleEffect(corePulse ? 1.12 : 0.9)
        }
        .frame(width: size, height: size)
        .onAppear {
            guard animate else { return }
            withAnimation(.easeOut(duration: 1.9).repeatForever(autoreverses: false)) {
                shockwaveOut = true
            }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                corePulse = true
            }
        }
    }
}

/// Poligono a raggiera: punte lunghe/corte alternate. Usata da Supernova.
private struct BurstShape: Shape {
    let points: Int
    let innerRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * innerRatio
        let totalPoints = points * 2
        var path = Path()
        for i in 0..<totalPoints {
            let angle = (Double(i) / Double(totalPoints)) * 2 * .pi - .pi / 2
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Pulsar (30 giorni): nucleo + due fasci che ruotano velocemente

private struct PulsarMark: View {
    let size: CGFloat
    let color: Color
    let spin: Bool
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            ForEach(0..<2, id: \.self) { i in
                BeamShape()
                    .fill(
                        LinearGradient(colors: [color.opacity(0.85), color.opacity(0)], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: size * 0.56, height: size * 0.16)
                    .offset(x: size * 0.28)
                    .rotationEffect(.degrees(Double(i) * 180))
            }
            Circle()
                .fill(RadialGradient(colors: [.white, color], center: .center, startRadius: 0, endRadius: size * 0.16))
                .frame(width: size * 0.3, height: size * 0.3)
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(rotation))
        .onAppear {
            guard spin else { return }
            withAnimation(.linear(duration: 3.2).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

private struct BeamShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Magnetar (50 giorni): nucleo + anelli di campo magnetico che "respirano"

private struct MagnetarMark: View {
    let size: CGFloat
    let color: Color
    let pulse: Bool
    @State private var expand = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Ellipse()
                    .stroke(color.opacity(0.65 - Double(i) * 0.16), lineWidth: 1.6)
                    .frame(width: size * (0.48 + CGFloat(i) * 0.22), height: size * (0.22 + CGFloat(i) * 0.12))
                    .rotationEffect(.degrees(Double(i) * 55))
            }
            Circle()
                .fill(RadialGradient(colors: [.white, color], center: .center, startRadius: 0, endRadius: size * 0.15))
                .frame(width: size * 0.28, height: size * 0.28)
        }
        .frame(width: size, height: size)
        .scaleEffect(pulse && expand ? 1.08 : 1.0)
        .onAppear {
            guard pulse else { return }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                expand = true
            }
        }
    }
}

// MARK: - Quasar (75 giorni): disco che ruota lentamente + getto che pulsa

private struct QuasarMark: View {
    let size: CGFloat
    let color: Color
    let animate: Bool

    @State private var diskRotation: Double = 0
    @State private var jetPulse = false

    var body: some View {
        ZStack {
            Ellipse()
                .stroke(color.opacity(0.55), lineWidth: 1.4)
                .frame(width: size * 0.62, height: size * 0.3)
                .rotationEffect(.degrees(diskRotation))

            Capsule()
                .fill(
                    LinearGradient(colors: [color.opacity(0), color, .white, color, color.opacity(0)], startPoint: .leading, endPoint: .trailing)
                )
                .frame(width: size * (jetPulse ? 1.28 : 1.02), height: size * 0.1)
                .opacity(jetPulse ? 1 : 0.65)

            Circle()
                .fill(RadialGradient(colors: [.white, color], center: .center, startRadius: 0, endRadius: size * 0.2))
                .frame(width: size * (jetPulse ? 0.38 : 0.3), height: size * (jetPulse ? 0.38 : 0.3))
        }
        .frame(width: size, height: size)
        .onAppear {
            guard animate else { return }
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                diskRotation = 360
            }
            withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                jetPulse = true
            }
        }
    }
}

// MARK: - Buco nero (ogni 100 giorni): disco di accrescimento che ruota +
// "orizzonte degli eventi" che pulsa verso l'esterno

private struct BlackHoleMark: View {
    let size: CGFloat
    let animate: Bool

    @State private var ringRotation: Double = 0
    @State private var horizonPulse = false

    var body: some View {
        ZStack {
            Ellipse()
                .stroke(
                    AngularGradient(colors: [.purple, .orange, .yellow, .purple], center: .center),
                    lineWidth: size * 0.09
                )
                .frame(width: size, height: size * 0.42)
                .rotationEffect(.degrees(-18 + ringRotation))

            Circle()
                .stroke(Color.purple.opacity(horizonPulse ? 0.05 : 0.35), lineWidth: 3)
                .frame(width: size * (horizonPulse ? 0.74 : 0.6), height: size * (horizonPulse ? 0.74 : 0.6))

            Circle()
                .fill(Color.black)
                .frame(width: size * 0.58, height: size * 0.58)
                .shadow(color: .purple.opacity(0.6), radius: 6)
        }
        .frame(width: size, height: size)
        .onAppear {
            guard animate else { return }
            withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) {
                horizonPulse = true
            }
        }
    }
}

// MARK: - Buco bianco (365 giorni, un anno intero): raggi che ruotano lenti +
// nucleo pulsante + anello che si espande verso l'esterno. Concettualmente
// l'opposto del buco nero: invece di "risucchiare" irradia luce verso fuori.
// È il traguardo più raro, quindi la stella più grande e vistosa di tutte.

private struct WhiteHoleMark: View {
    let size: CGFloat
    let animate: Bool

    @State private var rayRotation: Double = 0
    @State private var corePulse = false
    @State private var ringOut = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(ringOut ? 0 : 0.55), lineWidth: 2.4)
                .frame(
                    width: size * (ringOut ? 1.75 : 0.9),
                    height: size * (ringOut ? 1.75 : 0.9)
                )

            RayBurstShape(rayCount: 12)
                .stroke(
                    LinearGradient(colors: [.white, .yellow.opacity(0.6), .clear], startPoint: .center, endPoint: .bottom),
                    lineWidth: 1.6
                )
                .frame(width: size * 0.95, height: size * 0.95)
                .rotationEffect(.degrees(rayRotation))

            Circle()
                .fill(
                    RadialGradient(colors: [.white, .yellow.opacity(0.8), .orange.opacity(0.2), .clear], center: .center, startRadius: 0, endRadius: size * 0.4)
                )
                .frame(width: size * (corePulse ? 0.5 : 0.4), height: size * (corePulse ? 0.5 : 0.4))
        }
        .frame(width: size, height: size)
        .onAppear {
            guard animate else { return }
            withAnimation(.linear(duration: 9).repeatForever(autoreverses: false)) {
                rayRotation = 360
            }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                corePulse = true
            }
            withAnimation(.easeOut(duration: 2.2).repeatForever(autoreverses: false)) {
                ringOut = true
            }
        }
    }
}

/// Raggi che si irradiano dal centro, tipo bagliore solare. Usata dal Buco Bianco.
private struct RayBurstShape: Shape {
    let rayCount: Int

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        for i in 0..<rayCount {
            let angle = (Double(i) / Double(rayCount)) * 2 * .pi
            let end = CGPoint(x: center.x + CGFloat(cos(angle)) * radius, y: center.y + CGFloat(sin(angle)) * radius)
            path.move(to: center)
            path.addLine(to: end)
        }
        return path
    }
}
