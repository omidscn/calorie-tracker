import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var calorieService = CalorieEstimationService()
    @State private var foodLookupService = FoodLookupService()
    @State private var viewModel = DayLogViewModel()

    var body: some View {
        DayLogView(viewModel: viewModel)
            .environment(calorieService)
            .environment(foodLookupService)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FoodEntry.self, WeightEntry.self], inMemory: true)
}
