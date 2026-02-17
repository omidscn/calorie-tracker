import SwiftUI
import SwiftData

@main
struct calorie_trackerApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var authService = AuthService()

    let modelContainer: ModelContainer

    init() {
        let schema = Schema([FoodEntry.self, WeightEntry.self])
        let config = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        CloudSyncedDefaults.shared.startSyncing()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isLoading {
                    ProgressView()
                } else if !authService.isAuthenticated {
                    LoginView()
                } else if !hasCompletedOnboarding {
                    OnboardingView()
                } else {
                    ContentView()
                }
            }
            .environment(authService)
        }
        .modelContainer(modelContainer)
    }
}
