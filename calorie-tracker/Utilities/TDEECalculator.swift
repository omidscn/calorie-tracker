import Foundation

enum BiologicalSex: String, CaseIterable {
    case male
    case female

    var displayName: String {
        switch self {
        case .male: "Male"
        case .female: "Female"
        }
    }

    var icon: String {
        switch self {
        case .male: "figure.stand"
        case .female: "figure.stand.dress"
        }
    }
}

enum ActivityLevel: String, CaseIterable {
    case sedentary
    case lightlyActive
    case moderatelyActive
    case veryActive
    case extraActive

    var multiplier: Double {
        switch self {
        case .sedentary: 1.2
        case .lightlyActive: 1.375
        case .moderatelyActive: 1.55
        case .veryActive: 1.725
        case .extraActive: 1.9
        }
    }

    var displayName: String {
        switch self {
        case .sedentary: "Sedentary"
        case .lightlyActive: "Lightly Active"
        case .moderatelyActive: "Moderately Active"
        case .veryActive: "Very Active"
        case .extraActive: "Extra Active"
        }
    }

    var description: String {
        switch self {
        case .sedentary: "Little or no exercise, desk job"
        case .lightlyActive: "Light exercise 1–3 days/week"
        case .moderatelyActive: "Moderate exercise 3–5 days/week"
        case .veryActive: "Hard exercise 6–7 days/week"
        case .extraActive: "Very hard exercise, physical job"
        }
    }

    var icon: String {
        switch self {
        case .sedentary: "figure.stand"
        case .lightlyActive: "figure.walk"
        case .moderatelyActive: "figure.run"
        case .veryActive: "figure.highintensity.intervaltraining"
        case .extraActive: "figure.strengthtraining.traditional"
        }
    }
}

enum WeightGoal: String, CaseIterable {
    case lose
    case maintain
    case gain

    var calorieAdjustment: Int {
        switch self {
        case .lose: -500
        case .maintain: 0
        case .gain: 500
        }
    }

    var displayName: String {
        switch self {
        case .lose: "Lose Weight"
        case .maintain: "Maintain"
        case .gain: "Gain Weight"
        }
    }

    var subtitle: String {
        switch self {
        case .lose: "~0.5 kg/week loss"
        case .maintain: "Stay at current weight"
        case .gain: "~0.5 kg/week gain"
        }
    }

    var icon: String {
        switch self {
        case .lose: "arrow.down.right"
        case .maintain: "arrow.right"
        case .gain: "arrow.up.right"
        }
    }
}

enum TDEECalculator {
    /// Approximate kcal energy in 1 kg of body fat.
    static let kcalPerKg: Double = 7700

    static func calculateBMR(sex: BiologicalSex, weightKg: Double, heightCm: Double, age: Int) -> Double {
        let base = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * Double(age))
        switch sex {
        case .male: return base + 5.0
        case .female: return base - 161.0
        }
    }

    static func calculateTDEE(sex: BiologicalSex, weightKg: Double, heightCm: Double, age: Int, activity: ActivityLevel) -> Double {
        calculateBMR(sex: sex, weightKg: weightKg, heightCm: heightCm, age: age) * activity.multiplier
    }

    static func calculateDailyCalorieGoal(sex: BiologicalSex, weightKg: Double, heightCm: Double, age: Int, activity: ActivityLevel, goal: WeightGoal) -> Int {
        let bmr = calculateBMR(sex: sex, weightKg: weightKg, heightCm: heightCm, age: age)
        let tdee = bmr * activity.multiplier
        let adjusted = tdee + Double(goal.calorieAdjustment)

        // Medical guidelines: never eat below these minimums without supervision
        // Men: 1500 kcal, Women: 1200 kcal (Harvard Health, Healthline)
        let sexMinimum: Double = sex == .male ? 1500 : 1200

        // Never go below the person's own BMR — eating below BMR impairs basic
        // organ function and requires medical supervision
        let safeFloor = max(sexMinimum, bmr)

        return max(Int(safeFloor.rounded()), Int(adjusted.rounded()))
    }

    /// Projected weekly weight change in kg (negative = loss).
    static func weeklyWeightChangeKg(dailyCalories: Int, tdee: Double) -> Double {
        let dailySurplus = Double(dailyCalories) - tdee
        return (dailySurplus * 7.0) / kcalPerKg
    }

    /// Weeks to reach target weight, or nil if the direction doesn't match or no change.
    static func weeksToTarget(currentKg: Double, targetKg: Double, weeklyChangeKg: Double) -> Int? {
        let diff = targetKg - currentKg
        guard abs(diff) > 0.1, abs(weeklyChangeKg) > 0.01 else { return nil }
        // Direction must match: losing weight needs negative change, gaining needs positive
        guard (diff < 0 && weeklyChangeKg < 0) || (diff > 0 && weeklyChangeKg > 0) else { return nil }
        return max(1, Int((diff / weeklyChangeKg).rounded(.up)))
    }

    /// Format weeks into a human-readable duration string.
    static func formatDuration(weeks: Int) -> String {
        if weeks < 4 {
            return weeks == 1 ? "~1 week" : "~\(weeks) weeks"
        }
        let months = weeks / 4
        let remainingWeeks = weeks % 4
        if remainingWeeks == 0 {
            return months == 1 ? "~1 month" : "~\(months) months"
        }
        if months == 0 {
            return "~\(remainingWeeks) weeks"
        }
        return "~\(months) mo \(remainingWeeks) wk"
    }
}
