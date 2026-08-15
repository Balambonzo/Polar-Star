import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth

@main
struct Full_FocusApp: App {
    init() {
        FirebaseApp.configure()
        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously { _, error in
                if let error {
                    print("Firebase anonymous sign-in error: \(error)")
                }
            }
        }
        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(AppModelContainer.shared)
    }
}
