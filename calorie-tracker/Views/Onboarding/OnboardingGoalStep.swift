import SwiftUI

struct OnboardingGoalStep: View {
    @Binding var weightGoal: WeightGoal
    @Binding var targetWeightKg: Double
    let currentWeightKg: Double

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Your Goal")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .padding(.top, 8)

                Text("What would you like to achieve?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 12) {
                    ForEach(WeightGoal.allCases, id: \.self) { goal in
                        Button {
                            withAnimation(.spring(duration: 0.3)) {
                                weightGoal = goal
                                if goal == .maintain {
                                    targetWeightKg = currentWeightKg
                                }
                            }
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: goal.icon)
                                    .font(.title)
                                    .foregroundStyle(colorFor(goal))
                                    .frame(width: 40)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(goal.displayName)
                                        .font(.body.weight(.semibold))
                                    Text(goal.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if weightGoal == goal {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.tint)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.ultraThinMaterial, in: .rect(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(weightGoal == goal ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if weightGoal != .maintain {
                    targetWeightCard
                }

                Spacer()
            }
            .padding()
        }
    }

    private var targetWeightCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Target Weight")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Button {
                    withAnimation { targetWeightKg = max(30, targetWeightKg - 0.5) }
                } label: {
                    Image(systemName: "minus")
                        .font(.title3.weight(.medium))
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", targetWeightKg))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("kg")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Button {
                    withAnimation { targetWeightKg = min(300, targetWeightKg + 0.5) }
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.medium))
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
            }

            let diff = abs(targetWeightKg - currentWeightKg)
            if diff > 0.1 {
                Text(String(format: "%.1f kg %@", diff, weightGoal == .lose ? "to lose" : "to gain"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 20))
    }

    private func colorFor(_ goal: WeightGoal) -> Color {
        switch goal {
        case .lose: .green
        case .maintain: .blue
        case .gain: .orange
        }
    }
}
