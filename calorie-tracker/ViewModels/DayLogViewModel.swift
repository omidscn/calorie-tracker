import Foundation
import SwiftData

@Observable
final class DayLogViewModel {
    func createEntryFromText(
        _ text: String,
        date: Date,
        mealType: MealType,
        context: ModelContext,
        calorieService: CalorieEstimationService
    ) async throws {
        let estimate = try await calorieService.estimate(from: text)

        let entry = FoodEntry(
            rawInput: text,
            foodName: estimate.foodName,
            calories: estimate.totalCalories,
            proteinGrams: estimate.proteinGrams,
            carbsGrams: estimate.carbsGrams,
            fatGrams: estimate.fatGrams,
            quantity: estimate.quantity,
            source: "ai",
            mealType: mealType,
            timestamp: Self.combineDateWithCurrentTime(date: date)
        )

        context.insert(entry)
    }

    func createManualEntry(
        _ input: String,
        calories: Int,
        date: Date,
        mealType: MealType,
        context: ModelContext
    ) {
        let entry = FoodEntry(
            rawInput: input,
            foodName: input,
            calories: calories,
            quantity: 1.0,
            source: "manual",
            mealType: mealType,
            timestamp: Self.combineDateWithCurrentTime(date: date)
        )

        context.insert(entry)
    }

    func createEntryFromBarcode(
        _ barcode: String,
        date: Date,
        mealType: MealType,
        context: ModelContext,
        foodLookupService: FoodLookupService
    ) async throws {
        let product = try await foodLookupService.lookupBarcode(barcode)

        let entry = FoodEntry(
            rawInput: product.name,
            foodName: product.name,
            calories: product.calories,
            proteinGrams: product.proteinGrams,
            carbsGrams: product.carbsGrams,
            fatGrams: product.fatGrams,
            quantity: 1.0,
            source: "barcode",
            mealType: mealType,
            barcode: barcode,
            timestamp: Self.combineDateWithCurrentTime(date: date)
        )

        context.insert(entry)
    }

    private static func combineDateWithCurrentTime(date: Date) -> Date {
        let calendar = Calendar.current
        let now = Date.now

        if calendar.isDate(date, inSameDayAs: now) {
            return now
        }

        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: now)
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)

        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        combined.second = timeComponents.second

        return calendar.date(from: combined) ?? now
    }
}
