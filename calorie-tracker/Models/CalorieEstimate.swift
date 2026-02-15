import Foundation

struct CalorieEstimate: Decodable {
    var foodName: String
    var totalCalories: Int
    var proteinGrams: Double
    var carbsGrams: Double
    var fatGrams: Double
    var quantity: Double
}
