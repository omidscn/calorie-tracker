import Foundation

@Observable
final class FoodLookupService {
    func searchProducts(_ query: String) async throws -> [BarcodeProduct] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://world.openfoodfacts.org/cgi/search.pl?search_terms=\(encoded)&json=1&page_size=5&fields=product_name,nutriments,serving_quantity") else {
            return []
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let products = json["products"] as? [[String: Any]] else {
            return []
        }

        return products.compactMap { product in
            let name = product["product_name"] as? String ?? ""
            guard !name.isEmpty else { return nil }

            let nutriments = product["nutriments"] as? [String: Any] ?? [:]
            let caloriesPer100g = (nutriments["energy-kcal_100g"] as? Double) ?? 0
            guard caloriesPer100g > 0 else { return nil }

            let proteinPer100g = nutriments["proteins_100g"] as? Double
            let carbsPer100g = nutriments["carbohydrates_100g"] as? Double
            let fatPer100g = nutriments["fat_100g"] as? Double

            let servingSize = (product["serving_quantity"] as? Double) ?? 100
            let factor = servingSize / 100.0

            return BarcodeProduct(
                name: name,
                calories: Int(caloriesPer100g * factor),
                proteinGrams: proteinPer100g.map { $0 * factor },
                carbsGrams: carbsPer100g.map { $0 * factor },
                fatGrams: fatPer100g.map { $0 * factor },
                servingSize: servingSize
            )
        }
    }

    func lookupBarcode(_ barcode: String) async throws -> BarcodeProduct {
        let url = URL(string: "https://world.openfoodfacts.org/api/v0/product/\(barcode).json")!
        let (data, _) = try await URLSession.shared.data(from: url)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let status = json["status"] as? Int, status == 1,
              let product = json["product"] as? [String: Any] else {
            throw FoodLookupError.productNotFound
        }

        let name = product["product_name"] as? String ?? "Unknown Product"
        let nutriments = product["nutriments"] as? [String: Any] ?? [:]

        let caloriesPer100g = (nutriments["energy-kcal_100g"] as? Double) ?? 0
        let proteinPer100g = nutriments["proteins_100g"] as? Double
        let carbsPer100g = nutriments["carbohydrates_100g"] as? Double
        let fatPer100g = nutriments["fat_100g"] as? Double

        let servingSize = (product["serving_quantity"] as? Double) ?? 100
        let factor = servingSize / 100.0

        return BarcodeProduct(
            name: name,
            calories: Int(caloriesPer100g * factor),
            proteinGrams: proteinPer100g.map { $0 * factor },
            carbsGrams: carbsPer100g.map { $0 * factor },
            fatGrams: fatPer100g.map { $0 * factor },
            servingSize: servingSize
        )
    }
}

struct BarcodeProduct {
    let name: String
    let calories: Int
    let proteinGrams: Double?
    let carbsGrams: Double?
    let fatGrams: Double?
    let servingSize: Double
}

enum FoodLookupError: LocalizedError {
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found. Try entering it manually."
        }
    }
}
