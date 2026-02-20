import Foundation
import Supabase
                                                                                                                                                                                                               
@Observable
final class CalorieEstimationService {
                                                                                                                                                                                                               
  func estimate(from input: String) async throws -> CalorieEstimate {
      guard let session = supabase.auth.currentSession else {
          throw CalorieEstimationError.notAuthenticated
      }
      let accessToken = session.accessToken

      let sanitizedInput = String(input.prefix(500))

      var request = URLRequest(url: URL(string: "https://api.omidsprivatehub.tech/v1/chat/completions")!)
      request.httpMethod = "POST"
      request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")

      let systemPrompt = """
      You are a registered dietitian with deep knowledge of international food composition databases (including USDA, EFSA, BLS, and other regional nutrition references). Your task is to provide accurate calorie and macronutrient estimates for foods from any country or cuisine.

      ## Estimation Process (follow these steps in order)
      1. Identify each food item and its preparation method from the user's input.
      2. Determine the quantity or serving size. If none is specified, use standard real-world portion sizes (see defaults below).
      3. Estimate the weight in grams for the described quantity.
      4. Look up typical nutritional values per 100g using the most appropriate regional nutrition reference for that food.
      5. Scale to the actual quantity and compute totals.
      6. Verify consistency: (protein × 4) + (carbs × 4) + (fat × 9) should be within ±10% of totalCalories. Adjust if needed.

      ## Portion Size Defaults (when NO size is specified)
      Use typical real-world serving sizes, NOT small dietary guideline servings:
      - Fruits: 1 medium piece (~150-180g)
      - Vegetables: 1 cup raw or ½ cup cooked (~80-90g)
      - Meat/Poultry/Fish: 1 palm-sized cooked portion (~140g / 5oz)
      - Rice/Pasta: 1 generous cooked cup (~200-250g)
      - Bread: 1 regular slice (~30g)
      - Eggs: 1 large egg (~50g)
      - Liquids/Beverages: 1 cup (240ml)

      ## Quantity Parsing
      - "3x Apples" → quantity: 3, totalCalories = calories for 3 apples
      - "2 slices of pizza" → quantity: 2, totalCalories = calories for 2 slices
      - "a bowl of rice" → quantity: 1, assume ~300g cooked rice
      - "Chicken breast" → quantity: 1, assume 1 medium breast (~170g cooked)
      - Always return totalCalories for the FULL quantity, never per-unit.

      ## Cooking Method
      - Account for cooking method when specified (grilled vs fried can add 50-100+ kcal from oil).
      - If no method is mentioned, assume the most common preparation for that food.
      - For restaurant food, assume generous portions with added oils/butter.

      ## Accuracy Rules
      - Round calories to the nearest 5 kcal.
      - Round macronutrients to nearest 0.5g.
      - When uncertain, prefer the middle of the plausible range rather than underestimating.
      - For branded or restaurant items, use known published nutrition data when available.

      ## Language
      Always return `foodName` and `servingDescription` in the same language as the user's input. If the user writes in German, respond with German food names. If in French, use French names. Only use English when the input is in English.

      ## Off-topic Input
      If the input cannot be reasonably interpreted as a food, drink, or meal description, respond with exactly:
      {"reasoning":"Input is not a food item.","foodName":"Unknown","servingDescription":"","totalCalories":0,"proteinGrams":0,"carbsGrams":0,"fatGrams":0,"quantity":0}

      ## Output Format
      Respond with raw JSON only. No markdown, no code fences, no explanation — just the JSON object.
      """

      let fewShotExamples: [[String: Any]] = [
          [
              "role": "user",
              "content": "3x Apples"
          ],
          [
              "role": "assistant",
              "content": "{\"reasoning\":\"The user wants 3 apples. A medium apple weighs ~182g. Standard nutrition data shows a medium apple has about 95 kcal, 0.5g protein, 25g carbs, 0.3g fat. For 3 apples: 285 kcal, 1.5g protein, 75g carbs, 0.9g fat. Consistency check: (1.5×4)+(75×4)+(0.9×9) = 6+300+8.1 = 314.1. That's ~10% over 285, which is due to fiber calories not being fully absorbed. 285 kcal is the well-established reference value so I'll keep it.\",\"foodName\":\"Medium Apple\",\"servingDescription\":\"3 medium apples (~546g total)\",\"totalCalories\":285,\"proteinGrams\":1.5,\"carbsGrams\":75,\"fatGrams\":1,\"quantity\":3}"
          ],
          [
              "role": "user",
              "content": "Big Mac"
          ],
          [
              "role": "assistant",
              "content": "{\"reasoning\":\"A McDonald's Big Mac has well-known published nutrition data. Per McDonald's official nutrition info: 550 kcal, 25g protein, 45g carbs, 30g fat. Consistency: (25×4)+(45×4)+(30×9) = 100+180+270 = 550. Perfect match.\",\"foodName\":\"McDonald's Big Mac\",\"servingDescription\":\"1 Big Mac sandwich (~215g)\",\"totalCalories\":550,\"proteinGrams\":25,\"carbsGrams\":45,\"fatGrams\":30,\"quantity\":1}"
          ],
          [
              "role": "user",
              "content": "grilled chicken breast with rice and veggies"
          ],
          [
              "role": "assistant",
              "content": "{\"reasoning\":\"Breaking down the composite meal: 1) Grilled chicken breast (~170g cooked): ~280 kcal, 53g protein, 0g carbs, 6g fat. 2) Cooked white rice (~200g, one generous cup): ~260 kcal, 5g protein, 57g carbs, 0.5g fat. 3) Mixed steamed vegetables (~100g): ~35 kcal, 2g protein, 7g carbs, 0.5g fat. Totals: 575 kcal, 60g protein, 64g carbs, 7g fat. Consistency: (60×4)+(64×4)+(7×9) = 240+256+63 = 559. Within 3% of 575, close enough — slight difference from rounding and fiber.\",\"foodName\":\"Grilled Chicken Breast with Rice & Veggies\",\"servingDescription\":\"1 chicken breast (~170g) + 1 cup rice (~200g) + mixed vegetables (~100g)\",\"totalCalories\":575,\"proteinGrams\":60,\"carbsGrams\":64,\"fatGrams\":7,\"quantity\":1}"
          ]
      ]

      var messages: [[String: Any]] = [
          ["role": "system", "content": systemPrompt]
      ]
      messages.append(contentsOf: fewShotExamples)
      messages.append(["role": "user", "content": "Estimate calories for: \"\(sanitizedInput)\""])

      let body: [String: Any] = [
          "messages": messages
      ]

      let requestData = try JSONSerialization.data(withJSONObject: body)
      request.httpBody = requestData

      if let requestJSON = String(data: requestData, encoding: .utf8) {
          print("📤 [Gemini Request] POST /v1/chat/completions")
          print("📤 [Gemini Request] Body: \(requestJSON)")
      }

      let (data, response) = try await URLSession.shared.data(for: request)

      let rawResponse = String(data: data, encoding: .utf8) ?? "<unable to decode>"
      print("📥 [Gemini Response] Raw: \(rawResponse)")

      guard let http = response as? HTTPURLResponse else {
          print("❌ [Gemini] Not an HTTP response")
          throw CalorieEstimationError.networkError
      }

      print("📥 [Gemini Response] Status: \(http.statusCode)")

      guard http.statusCode == 200 else {
          let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
          let message: String
          if let errorString = parsed?["error"] as? String {
              message = errorString
          } else if let errorObj = parsed?["error"] as? [String: Any],
                    let msg = errorObj["message"] as? String {
              message = msg
          } else {
              message = "HTTP \(http.statusCode)"
          }
          print("❌ [API] Error: \(message)")

          if http.statusCode == 429 {
              throw CalorieEstimationError.rateLimited(message)
          }
          throw CalorieEstimationError.apiError(message)
      }

      guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let rawContent = json["text"] as? String else {
          print("❌ [Gemini] Could not extract text from response")
          throw CalorieEstimationError.invalidResponse
      }

      // Strip markdown code fences (```json ... ``` or ``` ... ```) if present
      let trimmed = rawContent.trimmingCharacters(in: .whitespacesAndNewlines)
      let content: String
      if trimmed.hasPrefix("```") {
          content = trimmed
              .replacingOccurrences(of: "^```(?:json)?\\s*", with: "", options: .regularExpression)
              .replacingOccurrences(of: "\\s*```$", with: "", options: .regularExpression)
              .trimmingCharacters(in: .whitespacesAndNewlines)
      } else {
          content = trimmed
      }

      guard let contentData = content.data(using: .utf8) else {
          print("❌ [Gemini] Could not encode content as UTF-8")
          throw CalorieEstimationError.invalidResponse
      }

      print("✅ [Gemini] Parsed content: \(content)")

      let estimate = try JSONDecoder().decode(CalorieEstimate.self, from: contentData)
      print("✅ [Gemini] Decoded: \(estimate.foodName) — \(estimate.totalCalories) kcal (P:\(estimate.proteinGrams)g C:\(estimate.carbsGrams)g F:\(estimate.fatGrams)g) qty:\(estimate.quantity)")

      if estimate.foodName == "Unknown" && estimate.totalCalories == 0 {
          throw CalorieEstimationError.notFood
      }

      return estimate
  }
}

enum CalorieEstimationError: LocalizedError {
  case notAuthenticated
  case networkError
  case apiError(String)
  case invalidResponse
  case rateLimited(String)
  case notFood

  var errorDescription: String? {
      switch self {
      case .notAuthenticated:
          return "You must be signed in to use AI calorie estimation."
      case .networkError:
          return "Network request failed. Check your connection."
      case .apiError(let message):
          return "API error: \(message)"
      case .invalidResponse:
          return "Could not parse the AI response."
      case .rateLimited(let message):
          return message
      case .notFood:
          return "That doesn't look like a food item. Try something like \"2 eggs\" or \"chicken sandwich\"."
      }
  }
}
