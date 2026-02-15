import SwiftUI

struct EditEntrySheet: View {
    @Bindable var entry: FoodEntry
    @Environment(\.dismiss) private var dismiss

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
            .onChange(of: entry.calories) {
                entry.isCalorieOverridden = true
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
