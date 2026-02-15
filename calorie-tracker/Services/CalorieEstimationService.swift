import Foundation

@Observable
final class CalorieEstimationService {
    private let apiKey: String

    var isAvailable: Bool { !apiKey.isEmpty && apiKey != "your-api-key-here" }

    init() {
        self.apiKey = Configuration.openAIAPIKey
    }

    func estimate(from input: String) async throws -> CalorieEstimate {
        guard isAvailable else {
            throw CalorieEstimationError.missingAPIKey
        }

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "foodName": ["type": "string"],
                "totalCalories": ["type": "integer"],
                "proteinGrams": ["type": "number"],
                "carbsGrams": ["type": "number"],
                "fatGrams": ["type": "number"],
                "quantity": ["type": "number"]
            ],
            "required": ["foodName", "totalCalories", "proteinGrams", "carbsGrams", "fatGrams", "quantity"],
            "additionalProperties": false
        ]

        let body: [String: Any] = [
            "model": "gpt-5-mini",
            "messages": [
                [
                    "role": "system",
                    "content": "You are a nutrition expert. Estimate calories and macronutrients for food items. Parse quantities from input like '3x Apples' (quantity = 3). Provide total calories for the full quantity, not per unit."
                ],
                [
                    "role": "user",
                    "content": "Estimate the nutritional information for: \(input)"
                ]
            ],
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": "calorie_estimate",
                    "strict": true,
                    "schema": schema
                ]
            ]
        ]

        let requestData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = requestData

        if let requestJSON = String(data: requestData, encoding: .utf8) {
            print("📤 [OpenAI Request] POST /v1/chat/completions")
            print("📤 [OpenAI Request] Body: \(requestJSON)")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        let rawResponse = String(data: data, encoding: .utf8) ?? "<unable to decode>"
        print("📥 [OpenAI Response] Raw: \(rawResponse)")

        guard let http = response as? HTTPURLResponse else {
            print("❌ [OpenAI] Not an HTTP response")
            throw CalorieEstimationError.networkError
        }

        print("📥 [OpenAI Response] Status: \(http.statusCode)")

        guard http.statusCode == 200 else {
            let message = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"]
                .flatMap { ($0 as? [String: Any])?["message"] as? String }
                ?? "HTTP \(http.statusCode)"
            print("❌ [OpenAI] Error: \(message)")
            throw CalorieEstimationError.apiError(message)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String,
              let contentData = content.data(using: .utf8) else {
            print("❌ [OpenAI] Could not extract content from response")
            throw CalorieEstimationError.invalidResponse
        }

        print("✅ [OpenAI] Parsed content: \(content)")

        let estimate = try JSONDecoder().decode(CalorieEstimate.self, from: contentData)
        print("✅ [OpenAI] Decoded: \(estimate.foodName) — \(estimate.totalCalories) kcal (P:\(estimate.proteinGrams)g C:\(estimate.carbsGrams)g F:\(estimate.fatGrams)g) qty:\(estimate.quantity)")

        return estimate
    }
}

enum CalorieEstimationError: LocalizedError {
    case missingAPIKey
    case networkError
    case apiError(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key not set. Add your key to the .env file at the project root."
        case .networkError:
            return "Network request failed. Check your connection."
        case .apiError(let message):
            return "OpenAI error: \(message)"
        case .invalidResponse:
            return "Could not parse the AI response."
        }
    }
}
