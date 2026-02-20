import SwiftUI
import SwiftData

struct BarcodeConfirmationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let product: BarcodeProduct
    let barcode: String?
    let viewModel: DayLogViewModel
    let date: Date
    let mealType: MealType

    @State private var quantity: Double = 1.0

    private var scaledCalories: Int {
        Int(Double(product.calories) * quantity)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            Capsule()
                .fill(.secondary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            ScrollView {
                VStack(spacing: 28) {
                    // Product info
                    VStack(spacing: 6) {
                        Text(product.name)
                            .font(.title3.weight(.semibold))
                            .multilineTextAlignment(.center)

                        Text("per \(Int(product.servingSize))g serving")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 12)

                    // Calorie count
                    VStack(spacing: 4) {
                        Text("\(scaledCalories)")
                            .font(.system(size: 56, weight: .black, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())

                        Text("kcal")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Macros
                    if product.proteinGrams != nil || product.carbsGrams != nil || product.fatGrams != nil {
                        HStack(spacing: 0) {
                            if let p = product.proteinGrams {
                                macroCell(label: "Protein", value: p * quantity, color: .blue)
                            }
                            if let c = product.carbsGrams {
                                macroCell(label: "Carbs", value: c * quantity, color: .orange)
                            }
                            if let f = product.fatGrams {
                                macroCell(label: "Fat", value: f * quantity, color: .yellow)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Quantity stepper
                    VStack(spacing: 10) {
                        Text("Servings")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 32) {
                            Button {
                                guard quantity > 0.5 else { return }
                                withAnimation(.spring(duration: 0.2)) {
                                    quantity -= 0.5
                                }
                            } label: {
                                Image(systemName: "minus")
                                    .font(.title3.weight(.bold))
                                    .frame(width: 52, height: 52)
                                    .glassEffect(.regular.interactive(), in: .circle)
                            }
                            .buttonStyle(.plain)

                            Text(quantity == quantity.rounded() ? "\(Int(quantity))" : String(format: "%.1f", quantity))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .frame(minWidth: 48)

                            Button {
                                withAnimation(.spring(duration: 0.2)) {
                                    quantity += 0.5
                                }
                            } label: {
                                Image(systemName: "plus")
                                    .font(.title3.weight(.bold))
                                    .frame(width: 52, height: 52)
                                    .glassEffect(.regular.interactive(), in: .circle)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }

            // Add button
            VStack(spacing: 0) {
                Divider()

                Button {
                    addEntry()
                } label: {
                    Text("Add to Log")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.blue, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(.ultraThinMaterial)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }

    private func macroCell(label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(Int(value))g")
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private func addEntry() {
        viewModel.createEntryFromScannedProduct(
            product,
            quantity: quantity,
            barcode: barcode,
            date: date,
            mealType: mealType,
            context: modelContext
        )
        dismiss()
    }
}
