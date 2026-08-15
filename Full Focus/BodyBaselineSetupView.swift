import SwiftUI

struct BodyBaselineSetupView: View {
    @Binding var levels: [String: Int]
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("What's your training?")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.top, 30)

            Text("Click every part of the body to mark how many times you've trained it, from ligth (a bit) to purple (a lot). This is just a starting point, the map will be updated with new trainings.")
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            InteractiveBodyFigureView(levels: levels, selected: []) { muscle in
                            let current = levels[muscle] ?? 0
                            levels[muscle] = (current + 1) % 5
                        }
            .frame(maxWidth: 220)
            .padding(.vertical, 10)

            Spacer()

            Button {
                onContinue()
            } label: {
                Text("Next")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}
