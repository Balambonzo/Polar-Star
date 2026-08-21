//import SwiftUI
//import SwiftData
//
//struct ContentView: View {
//    @Query private var profiles: [UserProfile]
//
//    private var selectedActivities: [String] {
//        profiles.first?.selectedActivities ?? []
//    }
//
//    var body: some View {
//        TabView {
//            TodayView()
//                .tabItem { Label("Today", systemImage: "flame.fill") }
//            ConstellationView()
//                .tabItem { Label("Constellation", systemImage: "square.grid.3x3.fill") }
//            if selectedActivities.contains(ActivityKey.training.rawValue) {
//                TrainingView()
//                    .tabItem { Label("Training", systemImage: "figure.strengthtraining.traditional") }
//            }
//            if selectedActivities.contains(ActivityKey.reading.rawValue) {
//                LibraryView()
//                    .tabItem { Label("Bookshelf", systemImage: "books.vertical.fill") }
//            }
//            if selectedActivities.contains(ActivityKey.custom.rawValue) {
//                JollyActivityShelfView()
//                    .tabItem { Label("Jolly", systemImage: "star.fill") }
//            }
//            ProfileView()
//                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
//        }
//        .tint(.orange)
//        .persistentSystemOverlays(.visible)
//        .onAppear { Self.configureTabBarAppearanceOnce }
//    }
//
//    /// Eseguito una sola volta per l'intera vita del processo, non ad
//    /// ogni ricreazione di ContentView.
//    private static let configureTabBarAppearanceOnce: Void = {
//        let appearance = UITabBarAppearance()
//        appearance.configureWithTransparentBackground()
//        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
//        UITabBar.appearance().standardAppearance = appearance
//        UITabBar.appearance().scrollEdgeAppearance = appearance
//    }()
//}
import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var profiles: [UserProfile]

    private var selectedActivities: [String] {
        profiles.first?.selectedActivities ?? []
    }

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "flame.fill") }
            ConstellationView()
                .tabItem { Label("Constellation", systemImage: "square.grid.3x3.fill") }
            if selectedActivities.contains("training") {
                TrainingView()
                    .tabItem { Label("Training", systemImage: "figure.strengthtraining.traditional") }
            }
            if selectedActivities.contains("reading") {
                LibraryView()
                    .tabItem { Label("Bookshelf", systemImage: "books.vertical.fill") }
            }
            if selectedActivities.contains(ActivityKey.custom.rawValue) {
                JollyActivityShelfView()
                    .tabItem { Label("Jolly", systemImage: "star.fill") }
            }
        }
        .tint(.orange)
        .persistentSystemOverlays(.visible)
        .onAppear { Self.configureTabBarAppearanceOnce }
    }

    /// Eseguito una sola volta per l'intera vita del processo, non ad
    /// ogni ricreazione di ContentView.
    private static let configureTabBarAppearanceOnce: Void = {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }()
}
