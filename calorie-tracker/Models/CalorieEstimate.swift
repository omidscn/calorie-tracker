import Foundation

struct CalorieEstimate: Decodable {
    var reasoning: String
    var foodName: String
    var servingDescription: String
    var totalCalories: Double
    var proteinGrams: Double
    var carbsGrams: Double
    var fatGrams: Double
    var quantity: Double
}
