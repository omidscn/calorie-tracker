import Foundation
import SwiftData

struct SavedMealItem: Codable, Hashable, Identifiable {
    var id: UUID
    var foodName: String
    var calories: Int
    var proteinGrams: Double?
    var carbsGrams: Double?
    var fatGrams: Double?
    var servingSize: Double
    var quantity: Double

    init(id: UUID = UUID(), foodName: String, calories: Int, proteinGrams: Double? = nil, carbsGrams: Double? = nil, fatGrams: Double? = nil, servingSize: Double, quantity: Double) {
        self.id = id
        self.foodName = foodName
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
        self.servingSize = servingSize
        self.quantity = quantity
    }

    init(product: BarcodeProduct, quantity: Double) {
        self.id = UUID()
        self.foodName = product.name
        self.calories = product.calories
        self.proteinGrams = product.proteinGrams
        self.carbsGrams = product.carbsGrams
        self.fatGrams = product.fatGrams
        self.servingSize = product.servingSize
        self.quantity = quantity
    }

    var asBarcodeProduct: BarcodeProduct {
        BarcodeProduct(
            name: foodName,
            calories: calories,
            proteinGrams: proteinGrams,
            carbsGrams: carbsGrams,
            fatGrams: fatGrams,
            servingSize: servingSize
        )
    }
}

@Model
final class SavedMeal {
    var name: String = ""
    var itemsData: Data = Data()
    var totalCalories: Int = 0
    var totalProtein: Double = 0
    var totalCarbs: Double = 0
    var totalFat: Double = 0
    var createdAt: Date = Date.now
    var lastUsedAt: Date = Date.now

    var items: [SavedMealItem] {
        get {
            (try? JSONDecoder().decode([SavedMealItem].self, from: itemsData)) ?? []
        }
        set {
            itemsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    init(name: String, items: [SavedMealItem]) {
        self.name = name
        self.itemsData = (try? JSONEncoder().encode(items)) ?? Data()
        self.totalCalories = items.reduce(0) { $0 + Int(Double($1.calories) * $1.quantity) }
        self.totalProtein = items.reduce(0) { $0 + ($1.proteinGrams ?? 0) * $1.quantity }
        self.totalCarbs = items.reduce(0) { $0 + ($1.carbsGrams ?? 0) * $1.quantity }
        self.totalFat = items.reduce(0) { $0 + ($1.fatGrams ?? 0) * $1.quantity }
        self.createdAt = .now
        self.lastUsedAt = .now
    }
}
