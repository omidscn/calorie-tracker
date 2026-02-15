import SwiftUI

struct OnboardingWelcomeStep: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "fork.knife.circle")
                .font(.system(size: 80))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("Calorie Tracker")
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                Text("Set up your personalized daily\ncalorie goal in just a few steps.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
            Spacer()
        }
        .padding()
    }
}
