import SwiftUI

struct MaintenanceView: View {
    let message: String

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.09)
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(red: 0.10, green: 0.18, blue: 0.55).opacity(0.40),
                    .clear
                ],
                center: .center,
                startRadius: 10,
                endRadius: 280
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                AppIcon(size: 100)

                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white.opacity(0.80))

                VStack(spacing: 12) {
                    Text("Under Maintenance")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    if !message.isEmpty {
                        Text(message)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
            }
        }
    }
}
