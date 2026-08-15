import SwiftUI
import SwiftData

/// Decide cosa mostrare all'avvio: onboarding se il profilo non è ancora
/// stato completato, altrimenti l'app vera e propria.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    var body: some View {
        if let profile = profiles.first {
            if profile.hasCompletedOnboarding {
                ContentView()
            } else {
                OnboardingView(profile: profile)
            }
        } else {
            ProgressView()
                .onAppear {
                    UserProfileStore.fetchOrCreate(in: modelContext)
                }
        }
    }
}
