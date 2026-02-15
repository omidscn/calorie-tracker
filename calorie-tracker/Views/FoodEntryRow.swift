import SwiftUI

struct FoodEntryRow: View {
    let entry: FoodEntry

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.foodName)
                        .font(.body)
                        .fontWeight(.medium)

                    if entry.isCalorieOverridden {
                        Image(systemName: "pencil")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    if entry.source == "barcode" {
                        Image(systemName: "barcode")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 8) {
                    if entry.quantity != 1.0 {
                        Text("\(entry.quantity, specifier: "%.1f")x")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(entry.timestamp.shortTimeString)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Text("\(entry.calories)")
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()

            Text("kcal")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
    }
}
