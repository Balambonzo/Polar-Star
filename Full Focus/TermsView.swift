import SwiftUI
import SafariServices

struct TermsView: View {
    private let termsURL = URL(string: "https://balambonzo.github.io/PolarStar-legal/")!
    @State private var showSafari = false

    var body: some View {
        ZStack {
            StarfieldBackground()
            VStack(spacing: 16) {
                Image(systemName: "doc.text")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)

                Text("Terms and Conditions")
                    .font(.title3.bold())
                    .foregroundStyle(Theme.textPrimary)

                Text("You can see our Terms and Conditions in the following link:")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button {
                    showSafari = true
                } label: {
                    Label("Open Terms and Conditions", systemImage: "safari")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.orange, in: Capsule())
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Terms and Conditions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showSafari) {
            SafariView(url: termsURL)
        }
    }
}

// Wrapper per usare SFSafariViewController in SwiftUI
private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
