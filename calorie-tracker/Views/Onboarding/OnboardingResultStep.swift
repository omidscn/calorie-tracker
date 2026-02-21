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

    private var sexMinimum: Double { sex == .male ? 1500 : 1200 }
    private var safeFloor: Double { max(sexMinimum, bmr) }
    private var adjustedCalories: Double { tdee + Double(weightGoal.calorieAdjustment) }
    private var isFloorApplied: Bool { weightGoal != .maintain && safeFloor > adjustedCalories }

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

                Text("Calculated using the Mifflin-St Jeor formula — a clinically validated method used by nutritionists worldwide.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                // Breakdown
                VStack(spacing: 12) {
                    breakdownRow(
                        label: "Basal Metabolic Rate",
                        subtitle: "Calories your body burns at complete rest",
                        value: "\(Int(bmr.rounded())) kcal"
                    )
                    Divider()
                    breakdownRow(
                        label: "Activity (\(activityLevel.displayName))",
                        subtitle: activityLevel.description,
                        value: "× \(String(format: "%.3g", activityLevel.multiplier))"
                    )
                    Divider()
                    breakdownRow(
                        label: "TDEE",
                        subtitle: "Total daily calories burned including activity",
                        value: "\(Int(tdee.rounded())) kcal"
                    )

                    if weightGoal != .maintain {
                        Divider()
                        breakdownRow(
                            label: "Goal adjustment",
                            subtitle: weightGoal == .lose ? "~0.5 kg/week deficit" : "~0.5 kg/week surplus",
                            value: "\(weightGoal.calorieAdjustment > 0 ? "+" : "")\(weightGoal.calorieAdjustment) kcal"
                        )
                    }

                    if isFloorApplied {
                        Divider()
                        breakdownRow(
                            label: "Safety minimum applied",
                            subtitle: safeFloor == bmr
                                ? "Never eat below your own BMR without medical supervision"
                                : "Recommended minimum for \(sex == .male ? "men" : "women")",
                            value: "\(Int(safeFloor.rounded())) kcal",
                            valueColor: .orange
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

    private func breakdownRow(label: String, subtitle: String? = nil, value: String, valueColor: Color = .primary) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Text(value)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(valueColor)
        }
    }
}
