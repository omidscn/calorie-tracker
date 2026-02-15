import SwiftUI
import SwiftData

struct DayLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(CalorieEstimationService.self) private var calorieService
    #if os(iOS)
    @Environment(FoodLookupService.self) private var foodLookupService
    #endif
    @Query(sort: \FoodEntry.timestamp, order: .reverse) private var allEntries: [FoodEntry]

    var viewModel: DayLogViewModel

    @State private var selectedDate: Date = .now
    @State private var inputText = ""
    @State private var selectedMealType: MealType = MealType.defaultForCurrentTime()
    @AppStorage("aiEnabled") private var aiEnabled = true
    @State private var isProcessing = false
    @State private var showBarcodeScanner = false
    @State private var selectedEntry: FoodEntry?
    @State private var errorMessage: String?
    @Namespace private var profileTransition
    @State private var transitionCounter = 0

    private var todaysEntries: [FoodEntry] {
        allEntries.filter { $0.timestamp.isSameDay(as: selectedDate) }
    }

    private var totalCalories: Int {
        todaysEntries.reduce(0) { $0 + $1.calories }
    }

    private var groupedEntries: [(MealType, [FoodEntry])] {
        MealType.allCases.compactMap { type in
            let entries = todaysEntries.filter { $0.meal == type }
            return entries.isEmpty ? nil : (type, entries)
        }
    }

    @AppStorage("dailyCalorieGoal") private var dailyCalorieGoal: Int = 2000

    var body: some View {
        NavigationStack {
        VStack(spacing: 0) {
            headerView

            List {
                ForEach(groupedEntries, id: \.0) { mealType, entries in
                    Section {
                        ForEach(entries) { entry in
                            Button {
                                selectedEntry = entry
                            } label: {
                                FoodEntryRow(entry: entry)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        modelContext.delete(entry)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        HStack(spacing: 6) {
                            Image(systemName: mealType.icon)
                            Text(mealType.rawValue)
                            Spacer()
                            Text("\(entries.reduce(0) { $0 + $1.calories }) kcal")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline.weight(.semibold))
                        .textCase(nil)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .overlay {
                if todaysEntries.isEmpty {
                    emptyStateView
                }
            }

            EntryInputBar(
                inputText: $inputText,
                selectedMealType: $selectedMealType,
                aiEnabled: $aiEnabled,
                onSubmit: { aiEnabled ? submitAIEntry() : submitManualEntry() },
                onBarcodeTap: { showBarcodeScanner = true },
                isProcessing: isProcessing
            )
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .onTapGesture {
            #if os(iOS)
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            #endif
        }
        .animation(.spring(duration: 0.3), value: todaysEntries.count)
        .animation(.default, value: selectedDate)
        .sheet(item: $selectedEntry) { entry in
            EditEntrySheet(entry: entry)
                .presentationDetents([.medium])
        }
        #if os(iOS)
        .sheet(isPresented: $showBarcodeScanner) {
            BarcodeScannerView { barcode in
                showBarcodeScanner = false
                Task { await handleBarcode(barcode) }
            }
        }
        #endif
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Button {
                    withAnimation {
                        selectedDate = Calendar.current.date(
                            byAdding: .day, value: -1, to: selectedDate
                        )!
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
                }

                Spacer()

                Text(selectedDate.displayString)
                    .font(.headline)

                Spacer()

                Button {
                    withAnimation {
                        selectedDate = Calendar.current.date(
                            byAdding: .day, value: 1, to: selectedDate
                        )!
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
            }
            .padding(.horizontal)

            NavigationLink {
                ProfileView()
                    #if os(iOS)
                    .navigationTransition(.zoom(sourceID: transitionCounter, in: profileTransition))
                    #endif
            } label: {
                HStack(alignment: .center, spacing: 4) {
                    VStack(spacing: 2) {
                        Text("\(totalCalories) kcal")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())

                        if dailyCalorieGoal > 0 {
                            Text("/ \(dailyCalorieGoal)")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .glassEffect(.regular.interactive(), in: .capsule)
            }
            .buttonStyle(.plain)
            #if os(iOS)
            .matchedTransitionSource(id: transitionCounter, in: profileTransition)
            #endif
            .onAppear { transitionCounter += 1 }
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No entries yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Type something like \"3x Apples\" below")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func submitAIEntry() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        inputText = ""
        isProcessing = true

        Task {
            do {
                try await viewModel.createEntryFromText(
                    text,
                    date: selectedDate,
                    mealType: selectedMealType,
                    context: modelContext,
                    calorieService: calorieService
                )
            } catch {
                errorMessage = error.localizedDescription
            }
            isProcessing = false
        }
    }

    private func submitManualEntry() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        let (name, calories) = parseManualInput(text)
        guard calories > 0 else { return }

        viewModel.createManualEntry(
            name,
            calories: calories,
            date: selectedDate,
            mealType: selectedMealType,
            context: modelContext
        )

        inputText = ""
    }

    private func parseManualInput(_ text: String) -> (name: String, calories: Int) {
        // Try to find a number anywhere in the text
        let parts = text.split(separator: " ")

        // If the whole thing is a number: "850"
        if let calories = Int(text) {
            return ("\(calories) kcal", calories)
        }

        // Find the last number in the string: "Pizza Salmone 850"
        if let lastNumber = parts.last, let calories = Int(lastNumber) {
            let name = parts.dropLast().joined(separator: " ")
            return (name.isEmpty ? "\(calories) kcal" : name, calories)
        }

        // Find the first number in the string: "850 Pizza Salmone"
        if let firstNumber = parts.first, let calories = Int(firstNumber) {
            let name = parts.dropFirst().joined(separator: " ")
            return (name.isEmpty ? "\(calories) kcal" : name, calories)
        }

        return (text, 0)
    }

    #if os(iOS)
    private func handleBarcode(_ barcode: String) async {
        isProcessing = true
        do {
            try await viewModel.createEntryFromBarcode(
                barcode,
                date: selectedDate,
                mealType: selectedMealType,
                context: modelContext,
                foodLookupService: foodLookupService
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }
    #endif
}
