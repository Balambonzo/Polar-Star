import SwiftUI

/// Stessa figura di BodyFigureView (stesse proporzioni, stessa scala di
/// colore), ma interattiva: ogni zona è tappabile e la selezione è
/// evidenziata con un bordo bianco. Usata nell'onboarding e nella scelta
/// delle zone da allenare.
struct InteractiveBodyFigureView: View {
    let levels: [String: Int]
    let selected: Set<String>
    let onTap: (String) -> Void
    var showFront: Bool = true

    private let maxLevel = 4
    private let strokeColor = Color(red: 0x3A/255, green: 0x32/255, blue: 0x2C/255)
    private let darkFill = Color(red: 0x2A/255, green: 0x24/255, blue: 0x20/255)

    private struct Zone {
        let muscle: String?
        let x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat
        let corner: CGFloat
        let isEllipse: Bool
    }

    private var zones: [Zone] {
        let shared: [Zone] = [
            Zone(muscle: nil, x: 92, y: 48, w: 16, h: 12, corner: 4, isEllipse: false),
            Zone(muscle: "Shoulders", x: 42, y: 59, w: 44, h: 30, corner: 0, isEllipse: true),
            Zone(muscle: "Shoulders", x: 114, y: 59, w: 44, h: 30, corner: 0, isEllipse: true),
            Zone(muscle: "Arms", x: 44, y: 82, w: 18, h: 46, corner: 9, isEllipse: false),
            Zone(muscle: "Arms", x: 138, y: 82, w: 18, h: 46, corner: 9, isEllipse: false),
            Zone(muscle: nil, x: 42, y: 128, w: 15, h: 40, corner: 7, isEllipse: false),
            Zone(muscle: nil, x: 143, y: 128, w: 15, h: 40, corner: 7, isEllipse: false),
            Zone(muscle: "Legs", x: 76, y: 186, w: 20, h: 58, corner: 10, isEllipse: false),
            Zone(muscle: "Legs", x: 104, y: 186, w: 20, h: 58, corner: 10, isEllipse: false),
            Zone(muscle: "Legs", x: 78, y: 246, w: 16, h: 42, corner: 8, isEllipse: false),
            Zone(muscle: "Legs", x: 106, y: 246, w: 16, h: 42, corner: 8, isEllipse: false)
        ]
        if showFront {
            return shared + [
                Zone(muscle: "Chest", x: 70, y: 70, w: 60, h: 44, corner: 14, isEllipse: false),
                Zone(muscle: "Core", x: 78, y: 126, w: 44, h: 56, corner: 10, isEllipse: false)
            ]
        } else {
            return shared + [
                Zone(muscle: "Back", x: 70, y: 70, w: 60, h: 54, corner: 14, isEllipse: false),
                Zone(muscle: "Legs", x: 76, y: 150, w: 48, h: 36, corner: 12, isEllipse: false)
            ]
        }
    }

    var body: some View {
        GeometryReader { geo in
            let scaleX = geo.size.width / 200
            let scaleY = geo.size.height / 300

            ZStack(alignment: .topLeading) {
                Circle()
                    .fill(darkFill)
                    .frame(width: 34 * min(scaleX, scaleY), height: 34 * min(scaleX, scaleY))
                    .position(x: 100 * scaleX, y: 34 * scaleY)

                ForEach(Array(zones.enumerated()), id: \.offset) { _, zone in
                    zoneShape(zone, scaleX: scaleX, scaleY: scaleY)
                }
            }
        }
        .aspectRatio(200.0 / 300.0, contentMode: .fit)
    }

    @ViewBuilder
    private func zoneShape(_ zone: Zone, scaleX: CGFloat, scaleY: CGFloat) -> some View {
        let fill = zone.muscle.map { color(for: $0) } ?? darkFill
        let isSelected = zone.muscle.map { selected.contains($0) } ?? false
        let width = zone.w * scaleX
        let height = zone.h * scaleY
        let centerX = (zone.x + zone.w / 2) * scaleX
        let centerY = (zone.y + zone.h / 2) * scaleY

        Group {
            if zone.isEllipse {
                Ellipse()
                    .fill(fill)
                    .overlay(Ellipse().stroke(isSelected ? Color.white : strokeColor, lineWidth: isSelected ? 3 : 1))
            } else {
                RoundedRectangle(cornerRadius: zone.corner * min(scaleX, scaleY))
                    .fill(fill)
                    .overlay(
                        RoundedRectangle(cornerRadius: zone.corner * min(scaleX, scaleY))
                            .stroke(isSelected ? Color.white : strokeColor, lineWidth: isSelected ? 3 : 1)
                    )
            }
        }
        .frame(width: width, height: height)
        .position(x: centerX, y: centerY)
        .onTapGesture {
            if let muscle = zone.muscle {
                onTap(muscle)
            }
        }
    }

    private func color(for muscle: String) -> Color {
        let level = levels[muscle] ?? 0
        let t = Double(min(max(level, 0), maxLevel)) / Double(maxLevel)
        if t < 0.05 {
            return Color(red: 0x35 / 255.0, green: 0x2D / 255.0, blue: 0x27 / 255.0)
        }
        let start = (r: 1.0, g: 0.85, b: 0.6)
        let end = (r: 0.55, g: 0.25, b: 0.85)
        let r = start.r + (end.r - start.r) * t
        let g = start.g + (end.g - start.g) * t
        let b = start.b + (end.b - start.b) * t
        return Color(red: r, green: g, blue: b)
    }
}
