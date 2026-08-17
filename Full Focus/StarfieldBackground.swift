import SwiftUI

/// Sfondo notturno condiviso da tutta l'app: gradiente blu scuro con
/// un campo di stelle statiche in lontananza che tremolano piano.
/// Usalo dietro ogni schermata per un'identità coerente.
struct StarfieldBackground: View {
    var starCount: Int = 60

    @State private var stars: [Star] = []
    @AppStorage("starfieldEnabled") private var starfieldEnabled = true

    private struct Star: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let baseOpacity: Double
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                            Theme.nightGradient

                            if starfieldEnabled {
                                ForEach(stars) { star in
                                    StaticStar(baseOpacity: star.baseOpacity)
                                        .frame(width: star.size, height: star.size)
                                        .position(x: star.x * geo.size.width, y: star.y * geo.size.height)
                                }
                            }
                        }
            .onAppear {
                if stars.isEmpty {
                    stars = (0..<starCount).map { _ in
                        Star(
                            x: .random(in: 0...1),
                            y: .random(in: 0...1),
                            size: .random(in: 1...2.6),
                            baseOpacity: .random(in: 0.5...1.0)
                        )
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

/// Le stelle sono volutamente statiche. Animare molte subview in un
/// GeometryReader a schermo intero ha causato instabilità di composizione
/// su alcune gerarchie SwiftUI/iOS 26.
private struct StaticStar: View {
    let baseOpacity: Double

    var body: some View {
        Circle()
            .fill(Color.white)
            .opacity(baseOpacity)
    }
}
