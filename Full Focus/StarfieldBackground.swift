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
                                    TwinklingStar(baseOpacity: star.baseOpacity)
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
                            baseOpacity: .random(in: 0.25...0.85)
                        )
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

private struct TwinklingStar: View {
    let baseOpacity: Double
    @State private var dim = false

    var body: some View {
        Circle()
            .fill(Color.white)
            .opacity(dim ? baseOpacity * 0.4 : baseOpacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: .random(in: 1.8...3.6))
                        .repeatForever(autoreverses: true)
                        .delay(.random(in: 0...2))
                ) {
                    dim = true
                }
            }
    }
}
