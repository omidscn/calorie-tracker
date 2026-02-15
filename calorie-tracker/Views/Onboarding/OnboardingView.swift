import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("dailyCalorieGoal") private var dailyCalorieGoal: Int = 2000
    @AppStorage("userBiologicalSex") private var userBiologicalSexRaw: String = "male"
    @AppStorage("userAge") private var userAge: Int = 25
    @AppStorage("userHeightCm") private var userHeightCm: Double = 170.0
    @AppStorage("userWeightKg") private var userWeightKg: Double = 70.0
    @AppStorage("userActivityLevel") private var userActivityLevelRaw: String = "moderatelyActive"
    @AppStorage("userWeightGoal") private var userWeightGoalRaw: String = "maintain"
    @AppStorage("userTargetWeightKg") private var userTargetWeightKg: Double = 70.0

    @State private var currentStep = 0
    @State private var sex: BiologicalSex = .male
    @State private var age: Int = 25
    @State private var heightCm: Double = 170.0
    @State private var weightKg: Double = 70.0
    @State private var activityLevel: ActivityLevel = .moderatelyActive
    @State private var weightGoal: WeightGoal = .maintain
    @State private var targetWeightKg: Double = 70.0

    private let totalSteps = 5

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 8)

            // Content
            TabView(selection: $currentStep) {
                OnboardingWelcomeStep()
                    .tag(0)

                OnboardingBodyStep(
                    sex: $sex,
                    age: $age,
                    heightCm: $heightCm,
                    weightKg: $weightKg
                )
                .tag(1)

                OnboardingActivityStep(activityLevel: $activityLevel)
                    .tag(2)

                OnboardingGoalStep(
                    weightGoal: $weightGoal,
                    targetWeightKg: $targetWeightKg,
                    currentWeightKg: weightKg
                )
                .tag(3)

                OnboardingResultStep(
                    sex: sex,
                    age: age,
                    heightCm: heightCm,
                    weightKg: weightKg,
                    activityLevel: activityLevel,
                    weightGoal: weightGoal,
                    onComplete: completeOnboarding
                )
                .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentStep)

            // Navigation buttons
            if currentStep < totalSteps - 1 {
                HStack {
                    if currentStep > 0 {
                        Button {
                            withAnimation { currentStep -= 1 }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .glassEffect(.regular.interactive(), in: .capsule)
                        }
                    }

                    Spacer()

                    Button {
                        withAnimation { currentStep += 1 }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .glassEffect(.regular.interactive(), in: .capsule)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
        }
    }

    private func completeOnboarding() {
        // Persist profile to AppStorage
        userBiologicalSexRaw = sex.rawValue
        userAge = age
        userHeightCm = heightCm
        userWeightKg = weightKg
        userActivityLevelRaw = activityLevel.rawValue
        userWeightGoalRaw = weightGoal.rawValue
        userTargetWeightKg = targetWeightKg

        // Calculate and set daily goal
        dailyCalorieGoal = TDEECalculator.calculateDailyCalorieGoal(
            sex: sex,
            weightKg: weightKg,
            heightCm: heightCm,
            age: age,
            activity: activityLevel,
            goal: weightGoal
        )

        // Insert initial weight entry
        let weightEntry = WeightEntry(weight: weightKg)
        modelContext.insert(weightEntry)

        // Mark onboarding complete
        hasCompletedOnboarding = true
    }
}
