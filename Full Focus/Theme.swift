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

    /// Leggero effetto di pressione — scala e attenua l'opacità al tocco.
    /// Aggiungilo a qualunque bottone vuoi rendere più "fisico" da usare.
    func pressable() -> some View {
        modifier(PressableModifier())
    }

    /// Bagliore morbido dietro la view, nel colore dato.
    func glow(_ color: Color, radius: CGFloat = 12) -> some View {
        self.shadow(color: color.opacity(0.5), radius: radius)
    }
}

private struct PressableModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.96 : 1)
            .opacity(isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}
