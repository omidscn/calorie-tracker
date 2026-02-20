import SwiftUI

struct OnboardingWelcomeStep: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            AppIcon(size: 120)

            VStack(spacing: 8) {
                Text("Calorie Tracker")
                    .font(.system(size: 36, weight: .black, design: .rounded))

                Text("AI-powered nutrition, made simple.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Text("Set up your personalized daily\ncalorie goal in just a few steps.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }

            Spacer()
            Spacer()
        }
        .padding()
    }
}
