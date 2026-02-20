import Foundation
import SwiftData

@Model
final class FavoriteFood {
    var name: String = ""
    var calories: Int = 0
    var proteinGrams: Double?
    var carbsGrams: Double?
    var fatGrams: Double?
    var servingSize: Double = 100
    var createdAt: Date = Date.now

    init(name: String, calories: Int, proteinGrams: Double?, carbsGrams: Double?, fatGrams: Double?, servingSize: Double) {
        self.name = name
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
        self.servingSize = servingSize
        self.createdAt = .now
    }

    convenience init(from product: BarcodeProduct) {
        self.init(
            name: product.name,
            calories: product.calories,
            proteinGrams: product.proteinGrams,
            carbsGrams: product.carbsGrams,
            fatGrams: product.fatGrams,
            servingSize: product.servingSize
        )
    }

    var asBarcodeProduct: BarcodeProduct {
        BarcodeProduct(
            name: name,
            calories: calories,
            proteinGrams: proteinGrams,
            carbsGrams: carbsGrams,
            fatGrams: fatGrams,
            servingSize: servingSize
        )
    }
}
