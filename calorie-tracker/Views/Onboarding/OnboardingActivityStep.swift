import SwiftUI

struct OnboardingActivityStep: View {
    @Binding var activityLevel: ActivityLevel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Activity Level")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .padding(.top, 8)

                Text("How active are you on a typical week?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 12) {
                    ForEach(ActivityLevel.allCases, id: \.self) { level in
                        Button {
                            withAnimation(.spring(duration: 0.3)) {
                                activityLevel = level
                            }
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: level.icon)
                                    .font(.title2)
                                    .frame(width: 36)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(level.displayName)
                                        .font(.body.weight(.semibold))
                                    Text(level.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if activityLevel == level {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.tint)
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial, in: .rect(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(activityLevel == level ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
    }
}
