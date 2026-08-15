import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var profiles: [UserProfile]

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    private var selectedActivities: [String] {
        profiles.first?.selectedActivities ?? []
    }

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "flame.fill") }
            ConstellationView()
                            .tabItem { Label("Costellazione", systemImage: "sparkles") }
            if selectedActivities.contains("training") {
                TrainingView()
                    .tabItem { Label("Training", systemImage: "figure.strengthtraining.traditional") }
            }
            if selectedActivities.contains("reading") {
                LibraryView()
                    .tabItem { Label("Bookshelf", systemImage: "books.vertical.fill") }
            }
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
        }
        .tint(.orange)
    }
}
