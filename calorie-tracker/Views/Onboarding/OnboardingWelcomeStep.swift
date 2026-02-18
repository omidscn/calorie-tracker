import SwiftUI

struct OnboardingWelcomeStep: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            SAFLogo(size: 120)

            VStack(spacing: 8) {
                Text("SAF")
                    .font(.system(size: 36, weight: .black, design: .rounded))

                Text("Simple as F** Calorie Tracker")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.safOrange)

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
