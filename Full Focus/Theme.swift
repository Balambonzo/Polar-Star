import SwiftUI

enum Theme {
    static let nightGradient = LinearGradient(
        colors: [
            Color(red: 0.04, green: 0.05, blue: 0.11),
            Color(red: 0.08, green: 0.09, blue: 0.18),
            Color(red: 0.05, green: 0.06, blue: 0.13)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let card = Color.white.opacity(0.06)
    static let cardBorder = Color.white.opacity(0.1)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.35)

    static let accent = Color.orange
    static let success = Color.green
    static let danger = Color.red

    static let cardRadius: CGFloat = 18
    static let smallRadius: CGFloat = 12
}

extension View {
    func glassCard(padding: CGFloat = 16, corner: CGFloat = Theme.cardRadius) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Theme.cardBorder, lineWidth: 1)
            )
    }

    /// Bagliore morbido dietro la view, nel colore dato.
    func glow(_ color: Color, radius: CGFloat = 12) -> some View {
        self.shadow(color: color.opacity(0.5), radius: radius)
    }
}

/// Leggero effetto di pressione — scala e attenua l'opacità al tocco.
/// Usalo con `.buttonStyle(PressableButtonStyle())` su qualunque `Button`
/// che vuoi rendere più "fisico" da usare. A differenza di una gesture
/// custom, `configuration.isPressed` è gestito dal sistema e non entra
/// in conflitto con lo scroll di una ScrollView circostante.
struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    var opacity: Double = 0.85

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? opacity : 1)
    }
}
