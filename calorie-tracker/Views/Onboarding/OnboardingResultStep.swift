import SwiftUI

struct OnboardingResultStep: View {
    let sex: BiologicalSex
    let age: Int
    let heightCm: Double
    let weightKg: Double
    let activityLevel: ActivityLevel
    let weightGoal: WeightGoal
    var buttonLabel: String = "Get Started"
    let onComplete: () -> Void

    private var bmr: Double {
        TDEECalculator.calculateBMR(sex: sex, weightKg: weightKg, heightCm: heightCm, age: age)
    }

    private var tdee: Double {
        TDEECalculator.calculateTDEE(sex: sex, weightKg: weightKg, heightCm: heightCm, age: age, activity: activityLevel)
    }

    private var dailyGoal: Int {
        TDEECalculator.calculateDailyCalorieGoal(sex: sex, weightKg: weightKg, heightCm: heightCm, age: age, activity: activityLevel, goal: weightGoal)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Your Daily Goal")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .padding(.top, 8)

                Text("\(dailyGoal)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text("kcal / day")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                // Breakdown
                VStack(spacing: 12) {
                    breakdownRow(label: "Base Metabolic Rate", value: "\(Int(bmr.rounded())) kcal")
                    Divider()
                    breakdownRow(label: "Activity (\(activityLevel.displayName))", value: "× \(String(format: "%.3g", activityLevel.multiplier))")
                    Divider()
                    breakdownRow(label: "TDEE", value: "\(Int(tdee.rounded())) kcal")

                    if weightGoal != .maintain {
                        Divider()
                        breakdownRow(
                            label: "Goal (\(weightGoal.displayName))",
                            value: "\(weightGoal.calorieAdjustment > 0 ? "+" : "")\(weightGoal.calorieAdjustment) kcal"
                        )
                    }

                    Divider()
                    HStack {
                        Text("Daily Target")
                            .font(.body.weight(.semibold))
                        Spacer()
                        Text("\(dailyGoal) kcal")
                            .font(.body.weight(.bold))
                            .foregroundStyle(.tint)
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 20))

                Spacer(minLength: 20)

                Button(action: onComplete) {
                    Text(buttonLabel)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .glassEffect(.regular.interactive(), in: .capsule)
                }
            }
            .padding()
        }
    }

    private func breakdownRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.monospacedDigit())
        }
    }
}
