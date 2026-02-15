import SwiftUI
import SwiftData

@main
struct calorie_trackerApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
            } else {
                OnboardingView()
            }
        }
        .modelContainer(for: [FoodEntry.self, WeightEntry.self])
    }
}
