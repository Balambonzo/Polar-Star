import SwiftUI

/// Overlay a schermo intero quando si raggiunge un nuovo traguardo della
/// streak — prima non succedeva nulla di visibile, ora il momento si sente.
struct MilestoneCelebrationView: View {
    let starType: StarType
    let streakDays: Int

    @State private var appeared = false
    @State private var burstParticles: [BurstParticle] = []

    private struct BurstParticle: Identifiable {
        let id = UUID()
        let angle: Double
        let distance: CGFloat
        let delay: Double
    }

    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.55 : 0)
                .ignoresSafeArea()

            ZStack {
                ForEach(burstParticles) { particle in
                    Circle()
                        .fill(starType.coreColor)
                        .frame(width: 6, height: 6)
                        .offset(
                            x: appeared ? cos(particle.angle) * particle.distance : 0,
                            y: appeared ? sin(particle.angle) * particle.distance : 0
                        )
                        .opacity(appeared ? 0 : 1)
                }

                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(starType.glowColor.opacity(0.35))
                            .frame(width: 140, height: 140)
                            .blur(radius: 20)

                        if starType == .blackHole {
                            Circle()
                                .stroke(starType.glowColor, lineWidth: 4)
                                .frame(width: 90, height: 90)
                            Circle()
                                .fill(Color.black)
                                .frame(width: 78, height: 78)
                        } else {
                            Circle()
                                .fill(starType.coreColor)
                                .frame(width: 84, height: 84)
                                .glow(starType.glowColor, radius: 24)
                        }
                    }
                    .scaleEffect(appeared ? 1 : 0.3)

                    Text(starType.displayName)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("\(streakDays) streak days!")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
            }
        }
        .onAppear {
            burstParticles = (0..<14).map { i in
                BurstParticle(
                    angle: Double(i) / 14 * 2 * .pi,
                    distance: CGFloat.random(in: 70...130),
                    delay: Double.random(in: 0...0.15)
                )
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                appeared = true
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

/// Ricorda l'ultimo traguardo già celebrato, per non ripetere la stessa
/// celebrazione ad ogni apertura dell'app.
enum MilestoneTracker {
    private static let key = "lastCelebratedStreakMilestone"

    static func checkAndConsume(currentStreak: Int) -> StarType? {
        guard let milestone = StarType.milestone(forStreakPosition: currentStreak) else { return nil }
        let last = UserDefaults.standard.integer(forKey: key)
        guard currentStreak > last else { return nil }
        UserDefaults.standard.set(currentStreak, forKey: key)
        return milestone
    }
}
