import SwiftUI
import SwiftData

@main
struct calorie_trackerApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var authService = AuthService()
    @State private var versionService = VersionCheckService()
    @State private var isSplashing = false
    @Environment(\.scenePhase) private var scenePhase

    let modelContainer: ModelContainer

    init() {
        let schema = Schema([FoodEntry.self, WeightEntry.self, SavedMeal.self, FavoriteFood.self])
        let config = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        CloudSyncedDefaults.shared.startSyncing()
    }

    private var showSplash: Bool { authService.isLoading || isSplashing || !versionService.hasChecked }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if !showSplash {
                    Group {
                        if !authService.isAuthenticated {
                            LoginView()
                        } else if !hasCompletedOnboarding {
                            OnboardingView()
                        } else {
                            ContentView()
                        }
                    }
                    .transition(.opacity)
                }

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }

                if versionService.response?.updateRequired == true {
                    ForceUpdateView(
                        message: versionService.response?.message ?? "",
                        storeUrl: versionService.response?.storeUrl ?? ""
                    )
                    .transition(.opacity)
                    .zIndex(2)
                } else if versionService.response?.isMaintenance == true {
                    MaintenanceView(message: versionService.response?.message ?? "")
                        .transition(.opacity)
                        .zIndex(2)
                }
            }
            .animation(.easeOut(duration: 0.35), value: showSplash)
            .animation(.easeOut(duration: 0.35), value: versionService.hasChecked)
            .environment(authService)
            .task { await versionService.checkVersion() }
            .onChange(of: scenePhase) { previous, current in
                if previous == .background && current == .active {
                    isSplashing = true
                    Task {
                        await versionService.checkVersion()
                        try? await Task.sleep(for: .milliseconds(700))
                        isSplashing = false
                    }
                }
            }
        }
        .modelContainer(modelContainer)
    }
}
