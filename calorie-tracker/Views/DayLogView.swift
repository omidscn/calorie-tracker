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
    @State private var showProfile = false

    private var todaysEntries: [FoodEntry] {
        allEntries.filter { $0.timestamp.isSameDay(as: selectedDate) }
    }

    private var totalCalories: Int {
        todaysEntries.reduce(0) { $0 + $1.calories }
    }

    private var remainingCalories: Int {
        Int(dailyCalorieGoal) - totalCalories
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
            mainContent
                .sheet(item: $selectedEntry) { entry in
                    EditEntrySheet(entry: entry)
                        .presentationDetents([.medium])
                }
                .sheet(isPresented: $showProfile) {
                    NavigationStack {
                        ProfileView()
                    }
                    .presentationDetents([.large])
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

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            headerView
            entryListView
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
    }

    // MARK: - Entry List

    private var entryListView: some View {
        ScrollViewReader { proxy in
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
                            .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
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

                Section {
                    Color.clear
                        .frame(height: 24)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .id("bottomAnchor")
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            #if os(iOS)
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo("bottomAnchor", anchor: .bottom)
                }
            }
            #endif
            .overlay {
                if todaysEntries.isEmpty {
                    emptyStateView
                }
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 12) {
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

            Button {
                showProfile = true
            } label: {
                VStack(spacing: 2) {
                    Text("\(remainingCalories) kcal")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())

                    Text("remains")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(.secondary)

                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .glassEffect(.regular.interactive(), in: .capsule)
            }
            .buttonStyle(.plain)
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
