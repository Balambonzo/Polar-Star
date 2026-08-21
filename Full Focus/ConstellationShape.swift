//ConstellationShape.swift
import CoreGraphics

/// Un pattern fisso di 6 posizioni relative (raggio massimo ≈ 1), usato sia
/// per disporre 6 stelle dentro una costellazione, sia per disporre 6
/// costellazioni dentro una galassia. Sempre lo stesso identico disegno,
/// niente di casuale: la forma la definisce l'indice, non il caso.
struct ConstellationShape {
    let name: String
    let points: [CGPoint] // esattamente 6 punti
}

enum ConstellationShapeLibrary {

    /// Le costellazioni "canoniche". Se un giorno vuoi aggiungerne altre,
    /// basta appenderle qui: l'assegnazione è ciclica sull'indice.
    static let shapes: [ConstellationShape] = [
        ConstellationShape(name: "hexagon", points: [
            CGPoint(x: 1.00, y: 0.00), CGPoint(x: 0.50, y: 0.87),
            CGPoint(x: -0.50, y: 0.87), CGPoint(x: -1.00, y: 0.00),
            CGPoint(x: -0.50, y: -0.87), CGPoint(x: 0.50, y: -0.87)
        ]),
        ConstellationShape(name: "arc", points: [
            CGPoint(x: -1.00, y: 0.20), CGPoint(x: -0.62, y: -0.35),
            CGPoint(x: -0.20, y: -0.62), CGPoint(x: 0.20, y: -0.62),
            CGPoint(x: 0.62, y: -0.35), CGPoint(x: 1.00, y: 0.20)
        ]),
        ConstellationShape(name: "zigzag", points: [
            CGPoint(x: -1.00, y: 0.55), CGPoint(x: -0.60, y: -0.55),
            CGPoint(x: -0.20, y: 0.55), CGPoint(x: 0.20, y: -0.55),
            CGPoint(x: 0.60, y: 0.55), CGPoint(x: 1.00, y: -0.55)
        ]),
        ConstellationShape(name: "cross", points: [
            CGPoint(x: 0.00, y: -1.00), CGPoint(x: 0.00, y: -0.35),
            CGPoint(x: -1.00, y: 0.10), CGPoint(x: 1.00, y: 0.10),
            CGPoint(x: 0.00, y: 0.45), CGPoint(x: 0.00, y: 1.00)
        ]),
        ConstellationShape(name: "spiralArm", points: {
            let goldenAngle = 2.399963
            return (0..<6).map { i -> CGPoint in
                let radius = 0.32 * sqrt(Double(i) + 1) * 2.1
                let angle = Double(i) * goldenAngle
                return CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            }
        }()),
        ConstellationShape(name: "vShape", points: [
            CGPoint(x: -1.00, y: -0.80), CGPoint(x: -0.62, y: -0.20),
            CGPoint(x: -0.24, y: 0.40), CGPoint(x: 0.24, y: 0.40),
            CGPoint(x: 0.62, y: -0.20), CGPoint(x: 1.00, y: -0.80)
        ]),
        ConstellationShape(name: "diamond", points: [
            CGPoint(x: 0.00, y: -1.00), CGPoint(x: 0.55, y: -0.30),
            CGPoint(x: 1.00, y: 0.45), CGPoint(x: 0.00, y: 1.00),
            CGPoint(x: -1.00, y: 0.45), CGPoint(x: -0.55, y: -0.30)
        ]),
        ConstellationShape(name: "wave", points: [
            CGPoint(x: -1.00, y: 0.00), CGPoint(x: -0.60, y: 0.62),
            CGPoint(x: -0.20, y: -0.62), CGPoint(x: 0.20, y: 0.62),
            CGPoint(x: 0.60, y: -0.62), CGPoint(x: 1.00, y: 0.00)
        ]),
        ConstellationShape(name: "fan", points: {
            (0..<6).map { i -> CGPoint in
                let angle = -0.9 + Double(i) * (1.8 / 5.0) // da -~51° a ~51°
                return CGPoint(x: sin(angle), y: -cos(angle) + 0.55)
            }
        }()),
        ConstellationShape(name: "staircase", points: [
            CGPoint(x: -1.00, y: -0.90), CGPoint(x: -0.60, y: -0.55),
            CGPoint(x: -0.20, y: -0.10), CGPoint(x: 0.20, y: 0.35),
            CGPoint(x: 0.60, y: 0.70), CGPoint(x: 1.00, y: 1.00)
        ]),
    ]

    static func shape(forIndex index: Int) -> ConstellationShape {
        let i = ((index % shapes.count) + shapes.count) % shapes.count
        return shapes[i]
    }
}
