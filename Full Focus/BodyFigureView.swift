import SwiftUI

/// Figura del corpo fronte/retro, colorata in base al volume settimanale
/// allenato per zona — stessa scala di FORGIA: grigio scuro (poco) →
/// arancione chiaro → arancione intenso (10-20+ set, ottimale).
struct BodyFigureView: View {
    let weeklySets: [String: Double]
    var showFront: Bool = true

    private let maxSets: Double = 16
    private let strokeColor = Color(red: 0x3A/255, green: 0x32/255, blue: 0x2C/255)
    private let darkFill = Color(red: 0x2A/255, green: 0x24/255, blue: 0x20/255)

    var body: some View {
        Canvas { context, size in
            let scaleX = size.width / 200
            let scaleY = size.height / 300

            func drawRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, corner: CGFloat, color: Color) {
                let r = CGRect(x: x * scaleX, y: y * scaleY, width: w * scaleX, height: h * scaleY)
                let path = Path(roundedRect: r, cornerRadius: corner * min(scaleX, scaleY))
                context.fill(path, with: .color(color))
                context.stroke(path, with: .color(strokeColor), lineWidth: 1)
            }

            func drawEllipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, color: Color) {
                let r = CGRect(x: (cx - rx) * scaleX, y: (cy - ry) * scaleY, width: rx * 2 * scaleX, height: ry * 2 * scaleY)
                let path = Path(ellipseIn: r)
                context.fill(path, with: .color(color))
                context.stroke(path, with: .color(strokeColor), lineWidth: 1)
            }

            drawEllipse(100, 34, 17, 17, color: darkFill)
            drawRect(92, 48, 16, 12, corner: 4, color: darkFill)

            if showFront {
                drawEllipse(64, 74, 22, 15, color: color(for: "Shoulders"))
                drawEllipse(136, 74, 22, 15, color: color(for: "Shoulders"))
                drawRect(70, 70, 60, 44, corner: 14, color: color(for: "Chest"))
                drawRect(44, 82, 18, 46, corner: 9, color: color(for: "Arms"))
                drawRect(138, 82, 18, 46, corner: 9, color: color(for: "Arms"))
                drawRect(42, 128, 15, 40, corner: 7, color: darkFill)
                drawRect(143, 128, 15, 40, corner: 7, color: darkFill)
                drawRect(78, 126, 44, 56, corner: 10, color: color(for: "Core"))
                drawRect(76, 186, 20, 58, corner: 10, color: color(for: "Legs"))
                drawRect(104, 186, 20, 58, corner: 10, color: color(for: "Legs"))
                drawRect(78, 246, 16, 42, corner: 8, color: color(for: "Legs"))
                drawRect(106, 246, 16, 42, corner: 8, color: color(for: "Legs"))
            } else {
                drawEllipse(64, 74, 22, 15, color: color(for: "Shoulders"))
                drawEllipse(136, 74, 22, 15, color: color(for: "Shoulders"))
                drawRect(70, 70, 60, 54, corner: 14, color: color(for: "Back"))
                drawRect(44, 82, 18, 46, corner: 9, color: color(for: "Arms"))
                drawRect(138, 82, 18, 46, corner: 9, color: color(for: "Arms"))
                drawRect(42, 128, 15, 40, corner: 7, color: darkFill)
                drawRect(143, 128, 15, 40, corner: 7, color: darkFill)
                drawRect(76, 150, 48, 36, corner: 12, color: color(for: "Legs"))
                drawRect(76, 186, 20, 58, corner: 10, color: color(for: "Legs"))
                drawRect(104, 186, 20, 58, corner: 10, color: color(for: "Legs"))
                drawRect(78, 246, 16, 42, corner: 8, color: color(for: "Legs"))
                drawRect(106, 246, 16, 42, corner: 8, color: color(for: "Legs"))
            }
        }
        .aspectRatio(200.0 / 300.0, contentMode: .fit)
    }

    private func color(for muscle: String) -> Color {
        BodyFigureView.fillColor(forWeeklySets: weeklySets[muscle] ?? 0, maxSets: maxSets)
    }

    static func fillColor(forWeeklySets sets: Double, maxSets: Double) -> Color {
        let t = min(max(sets / maxSets, 0), 1)
        if t < 0.05 {
            return Color(red: 0x35 / 255.0, green: 0x2D / 255.0, blue: 0x27 / 255.0)
        }
        let g = (138.0 - t * 32) / 255.0
        let b = (92.0 - t * 40) / 255.0
        let a = 0.35 + t * 0.65
        return Color(red: 1.0, green: g, blue: b, opacity: a)
    }
}
