import Foundation
import SwiftData

enum MealType: String, CaseIterable, Codable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"

    var icon: String {
        switch self {
        case .breakfast: "sunrise"
        case .lunch: "sun.max"
        case .dinner: "moon.stars"
        case .snack: "cup.and.saucer"
        }
    }

    static func defaultForCurrentTime() -> MealType {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 0..<11: return .breakfast
        case 11..<14: return .lunch
        case 14..<17: return .snack
        default: return .dinner
        }
    }
}

@Model
final class FoodEntry {
    var rawInput: String
    var foodName: String
    var calories: Int
    var proteinGrams: Double?
    var carbsGrams: Double?
    var fatGrams: Double?
    var quantity: Double
    var source: String
    var mealType: String
    var barcode: String?
    var timestamp: Date
    var isCalorieOverridden: Bool

    var meal: MealType {
        get { MealType(rawValue: mealType) ?? .snack }
        set { mealType = newValue.rawValue }
    }

    init(
        rawInput: String,
        foodName: String,
        calories: Int,
        proteinGrams: Double? = nil,
        carbsGrams: Double? = nil,
        fatGrams: Double? = nil,
        quantity: Double = 1.0,
        source: String = "manual",
        mealType: MealType = .snack,
        barcode: String? = nil,
        timestamp: Date = .now,
        isCalorieOverridden: Bool = false
    ) {
        self.rawInput = rawInput
        self.foodName = foodName
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
        self.quantity = quantity
        self.source = source
        self.mealType = mealType.rawValue
        self.barcode = barcode
        self.timestamp = timestamp
        self.isCalorieOverridden = isCalorieOverridden
    }
}
