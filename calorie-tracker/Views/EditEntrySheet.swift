import SwiftUI

struct EditEntrySheet: View {
    @Bindable var entry: FoodEntry
    @Environment(\.dismiss) private var dismiss

    @State private var caloriesPerUnit: Double
    @State private var proteinPerUnit: Double?
    @State private var carbsPerUnit: Double?
    @State private var fatPerUnit: Double?
    // Tracks the last calories value we set from a quantity change,
    // so we can distinguish it from a direct user edit.
    @State private var quantityDrivenCalories: Int = -1

    init(entry: FoodEntry) {
        self.entry = entry
        let q = max(entry.quantity, 0.001)
        _caloriesPerUnit = State(initialValue: Double(entry.calories) / q)
        _proteinPerUnit = State(initialValue: entry.proteinGrams.map { $0 / q })
        _carbsPerUnit = State(initialValue: entry.carbsGrams.map { $0 / q })
        _fatPerUnit = State(initialValue: entry.fatGrams.map { $0 / q })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Food") {
                    TextField("Food name", text: $entry.foodName)
                    LabeledContent("Original input") {
                        Text(entry.rawInput)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Calories") {
                    HStack {
                        TextField("Calories", value: $entry.calories, format: .number)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                            .font(.title2.bold())
                        Text("kcal")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Macros") {
                    macroRow("Protein (g)", value: $entry.proteinGrams)
                    macroRow("Carbs (g)", value: $entry.carbsGrams)
                    macroRow("Fat (g)", value: $entry.fatGrams)
                }

                Section("Meal") {
                    Picker("Meal type", selection: $entry.meal) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                }

                Section("Details") {
                    LabeledContent("Quantity") {
                        TextField("Qty", value: $entry.quantity, format: .number)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Source", value: entry.source)
                    if let barcode = entry.barcode {
                        LabeledContent("Barcode", value: barcode)
                    }
                }
            }
            .navigationTitle("Edit Entry")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: entry.quantity) { _, newQty in
                guard newQty > 0 else { return }
                let newCals = Int((caloriesPerUnit * newQty).rounded())
                quantityDrivenCalories = newCals
                entry.calories = newCals
                entry.proteinGrams = proteinPerUnit.map { $0 * newQty }
                entry.carbsGrams = carbsPerUnit.map { $0 * newQty }
                entry.fatGrams = fatPerUnit.map { $0 * newQty }
            }
            .onChange(of: entry.calories) {
                // Only treat as a manual override when the change wasn't caused by us
                if entry.calories != quantityDrivenCalories {
                    entry.isCalorieOverridden = true
                    let q = max(entry.quantity, 0.001)
                    caloriesPerUnit = Double(entry.calories) / q
                }
            }
        }
    }

    private func macroRow(_ title: String, value: Binding<Double?>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("--", value: value, format: .number)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
    }
}
