import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var calorieService = CalorieEstimationService()
    #if os(iOS)
    @State private var foodLookupService = FoodLookupService()
    #endif
    @State private var viewModel = DayLogViewModel()

    var body: some View {
        DayLogView(viewModel: viewModel)
            .environment(calorieService)
            #if os(iOS)
            .environment(foodLookupService)
            #endif
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FoodEntry.self, WeightEntry.self], inMemory: true)
}
