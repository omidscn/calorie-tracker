import SwiftUI

struct FoodEntryRow: View {
    let entry: FoodEntry

    var body: some View {
        HStack {
            Spacer(minLength: 60)

            VStack(alignment: .trailing, spacing: 0) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            if entry.quantity != 1.0 {
                                Text("\(entry.quantity, specifier: "%.0f")x")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.8))
                            }

                            Text(entry.foodName)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)

                            if entry.isCalorieOverridden {
                                Image(systemName: "pencil")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.6))
                            }

                            if entry.source == "barcode" {
                                Image(systemName: "barcode")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }

                        HStack(spacing: 4) {
                            Text(entry.timestamp.shortTimeString)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }

                    VStack(alignment: .trailing, spacing: 0) {
                        Text("\(entry.calories)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .monospacedDigit()
                            .foregroundStyle(.white)

                        Text("kcal")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Color.blue,
                    in: UnevenRoundedRectangle(
                        topLeadingRadius: 18,
                        bottomLeadingRadius: 18,
                        bottomTrailingRadius: 4,
                        topTrailingRadius: 18
                    )
                )
            }
        }
    }
}
