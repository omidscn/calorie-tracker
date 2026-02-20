import SwiftUI
import SwiftData

struct MealBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(FoodLookupService.self) private var foodLookupService

    var viewModel: DayLogViewModel
    var date: Date
    @State var mealType: MealType

    // Search state
    @State private var searchText = ""
    @State private var searchResults: [BarcodeProduct] = []
    @State private var items: [(id: UUID, product: BarcodeProduct, quantity: Double)] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    // Barcode scanning state
    @State private var showBarcodeScanner = false
    @State private var isLookingUpBarcode = false
    @State private var barcodeError: String?

    // Mode toggle state
    @State private var builderMode: BuilderMode = .build

    // Save meal state
    @State private var showSaveAlert = false
    @State private var saveMealName = ""

    // Saved meals query
    @Query(sort: \SavedMeal.lastUsedAt, order: .reverse) private var savedMeals: [SavedMeal]

    // Favorite foods query
    @Query(sort: \FavoriteFood.createdAt, order: .reverse) private var favoriteFoods: [FavoriteFood]

    private enum BuilderMode {
        case build, saved
    }

    private var totalCalories: Int {
        items.reduce(0) { $0 + Int(Double($1.product.calories) * $1.quantity) }
    }

    private var totalProtein: Double {
        items.reduce(0) { $0 + ($1.product.proteinGrams ?? 0) * $1.quantity }
    }

    private var totalCarbs: Double {
        items.reduce(0) { $0 + ($1.product.carbsGrams ?? 0) * $1.quantity }
    }

    private var totalFat: Double {
        items.reduce(0) { $0 + ($1.product.fatGrams ?? 0) * $1.quantity }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                modeToggle
                    .padding(.horizontal)
                    .padding(.top, 8)

                switch builderMode {
                case .build:
                    buildModeContent
                case .saved:
                    savedModeContent
                }

                summaryBar
            }
            .navigationTitle("Build a Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .principal) {
                    Menu {
                        ForEach(MealType.allCases, id: \.self) { type in
                            Button {
                                mealType = type
                            } label: {
                                Label(type.rawValue, systemImage: type.icon)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: mealType.icon)
                            Text("Build a Meal")
                                .fontWeight(.semibold)
                        }
                    }
                }

                if builderMode == .build && !items.isEmpty {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            saveMealName = ""
                            showSaveAlert = true
                        } label: {
                            Image(systemName: "bookmark")
                        }
                    }
                }
            }
            #if os(iOS)
            .sheet(isPresented: $showBarcodeScanner) {
                BarcodeScannerView { barcode in
                    showBarcodeScanner = false
                    lookupBarcode(barcode)
                }
            }
            #endif
            .alert("Save Meal", isPresented: $showSaveAlert) {
                TextField("Meal name", text: $saveMealName)
                Button("Cancel", role: .cancel) { }
                Button("Save") { saveMeal() }
                    .disabled(saveMealName.trimmingCharacters(in: .whitespaces).isEmpty)
            } message: {
                Text("Give this meal a name to save it for later.")
            }
            .alert("Barcode Error", isPresented: .init(
                get: { barcodeError != nil },
                set: { if !$0 { barcodeError = nil } }
            )) {
                Button("OK") { barcodeError = nil }
            } message: {
                if let error = barcodeError {
                    Text(error)
                }
            }
        }
        .onChange(of: searchText) {
            scheduleSearch()
        }
    }

    // MARK: - Mode Toggle

    private var modeToggle: some View {
        HStack(spacing: 0) {
            modeButton("Build", mode: .build)
            modeButton("Saved", mode: .saved)
        }
        .padding(4)
        .glassEffect(.regular, in: Capsule())
    }

    private func modeButton(_ title: String, mode: BuilderMode) -> some View {
        Button {
            withAnimation(.spring(duration: 0.3)) {
                builderMode = mode
            }
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(builderMode == mode ? 1 : 0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    builderMode == mode
                        ? AnyShapeStyle(.white.opacity(0.15))
                        : AnyShapeStyle(.clear),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Build Mode Content

    private var buildModeContent: some View {
        VStack(spacing: 0) {
            searchBar
                .padding(.horizontal)
                .padding(.top, 8)

            ScrollView {
                LazyVStack(spacing: 0) {
                    if !searchText.isEmpty {
                        searchResultsSection
                    } else if !favoriteFoods.isEmpty {
                        favoritesSection
                    } else if items.isEmpty {
                        emptyState
                    }

                    if !items.isEmpty {
                        mealItemsSection
                    }
                }
                .padding(.bottom, 100)
            }
        }
    }

    // MARK: - Saved Mode Content

    private var savedModeContent: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if savedMeals.isEmpty {
                    savedMealsEmptyState
                } else {
                    ForEach(savedMeals) { meal in
                        savedMealRow(meal)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 100)
        }
    }

    private var savedMealsEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bookmark")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.2))

            Text("No saved meals yet")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.5))

            Text("Build a meal and tap the bookmark icon to save it")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private func savedMealRow(_ meal: SavedMeal) -> some View {
        Button {
            loadSavedMeal(meal)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(meal.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text("\(meal.items.count) items")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(meal.totalCalories) kcal")
                        .font(.body)
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundStyle(.white)

                    HStack(spacing: 6) {
                        Text("P \(Int(meal.totalProtein))g")
                        Text("C \(Int(meal.totalCarbs))g")
                        Text("F \(Int(meal.totalFat))g")
                    }
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                modelContext.delete(meal)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.5))

            TextField("Search foods...", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()

            if isSearching || isLookingUpBarcode {
                ProgressView()
                    .controlSize(.small)
            } else if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            Button {
                showBarcodeScanner = true
            } label: {
                Image(systemName: "barcode.viewfinder")
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .capsule)
    }

    // MARK: - Search Results

    private var searchResultsSection: some View {
        LazyVStack(spacing: 8) {
            if searchResults.isEmpty && !isSearching && !searchText.isEmpty {
                Text("No results found")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, 40)
            } else {
                ForEach(Array(searchResults.enumerated()), id: \.offset) { _, product in
                    Button {
                        addItem(product)
                    } label: {
                        searchResultRow(product)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }

    private func searchResultRow(_ product: BarcodeProduct) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text("\(Int(product.servingSize))g serving")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(product.calories)")
                    .font(.body)
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundStyle(.white)

                HStack(spacing: 6) {
                    if let p = product.proteinGrams {
                        Text("P \(Int(p))")
                    }
                    if let c = product.carbsGrams {
                        Text("C \(Int(c))")
                    }
                    if let f = product.fatGrams {
                        Text("F \(Int(f))")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
            }

            Button {
                toggleFavorite(product)
            } label: {
                Image(systemName: isFavorite(product) ? "star.fill" : "star")
                    .font(.body)
                    .foregroundStyle(isFavorite(product) ? .yellow : .white.opacity(0.3))
            }
            .buttonStyle(.plain)

            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundStyle(.blue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Favorites Section

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Favorites", systemImage: "star.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal)
                .padding(.top, 12)

            ForEach(favoriteFoods) { favorite in
                Button {
                    addItem(favorite.asBarcodeProduct)
                } label: {
                    searchResultRow(favorite.asBarcodeProduct)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        modelContext.delete(favorite)
                    } label: {
                        Label("Remove from Favorites", systemImage: "star.slash")
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Meal Items

    private var mealItemsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Meal")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal)
                .padding(.top, 16)

            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                mealItemRow(index: index, item: item)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
        }
        .padding(.horizontal)
    }

    private func mealItemRow(index: Int, item: (id: UUID, product: BarcodeProduct, quantity: Double)) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.product.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text("\(Int(Double(item.product.calories) * item.quantity)) kcal")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    adjustQuantity(at: index, by: -0.5)
                } label: {
                    Image(systemName: "minus")
                        .font(.caption.weight(.bold))
                        .frame(width: 32, height: 32)
                        .foregroundStyle(.white)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
                .buttonStyle(.plain)

                Text("\(item.quantity, specifier: "%.1f")")
                    .font(.body)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .frame(minWidth: 32)
                    .contentTransition(.numericText())

                Button {
                    adjustQuantity(at: index, by: 0.5)
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                        .frame(width: 32, height: 32)
                        .foregroundStyle(.white)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
                .buttonStyle(.plain)
            }

            Button {
                removeItem(at: index)
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.8))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "takeoutbag.and.cup.and.straw")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.2))

            Text("Search for foods to build your meal")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    // MARK: - Summary Bar

    private var summaryBar: some View {
        VStack(spacing: 8) {
            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(totalCalories) kcal")
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())

                    HStack(spacing: 8) {
                        Text("P \(Int(totalProtein))g")
                        Text("C \(Int(totalCarbs))g")
                        Text("F \(Int(totalFat))g")
                    }
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.5))
                    .contentTransition(.numericText())
                }

                Spacer()

                Button {
                    logMeal()
                } label: {
                    Text("Log Meal (\(items.count) items)")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.blue, in: Capsule())
                }
                .disabled(items.isEmpty)
                .opacity(items.isEmpty ? 0.4 : 1)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Actions

    private func isFavorite(_ product: BarcodeProduct) -> Bool {
        favoriteFoods.contains { $0.name == product.name }
    }

    private func toggleFavorite(_ product: BarcodeProduct) {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif

        if let existing = favoriteFoods.first(where: { $0.name == product.name }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(FavoriteFood(from: product))
        }
    }

    private func scheduleSearch() {
        searchTask?.cancel()

        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))

            guard !Task.isCancelled else { return }

            await MainActor.run { isSearching = true }

            do {
                let results = try await foodLookupService.searchProducts(searchText)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run { isSearching = false }
            }
        }
    }

    private func addItem(_ product: BarcodeProduct) {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif

        withAnimation(.spring(duration: 0.3)) {
            items.append((id: UUID(), product: product, quantity: 1.0))
        }

        searchText = ""
        searchResults = []
    }

    private func adjustQuantity(at index: Int, by delta: Double) {
        guard items.indices.contains(index) else { return }
        let newQuantity = items[index].quantity + delta
        guard newQuantity >= 0.5 else { return }
        withAnimation(.spring(duration: 0.3)) {
            items[index].quantity = newQuantity
        }
    }

    private func removeItem(at index: Int) {
        guard items.indices.contains(index) else { return }
        withAnimation(.snappy(duration: 0.3)) {
            _ = items.remove(at: index)
        }
    }

    private func logMeal() {
        let mealItems = items.map { (product: $0.product, quantity: $0.quantity) }
        viewModel.createEntriesFromMealBuilder(
            mealItems,
            date: date,
            mealType: mealType,
            context: modelContext
        )
        dismiss()
    }

    private func lookupBarcode(_ barcode: String) {
        isLookingUpBarcode = true
        Task {
            do {
                let product = try await foodLookupService.lookupBarcode(barcode)
                await MainActor.run {
                    isLookingUpBarcode = false
                    addItem(product)
                }
            } catch {
                await MainActor.run {
                    isLookingUpBarcode = false
                    barcodeError = error.localizedDescription
                }
            }
        }
    }

    private func saveMeal() {
        let trimmedName = saveMealName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let savedItems = items.map { SavedMealItem(product: $0.product, quantity: $0.quantity) }
        let meal = SavedMeal(name: trimmedName, items: savedItems)
        modelContext.insert(meal)

        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    private func loadSavedMeal(_ meal: SavedMeal) {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif

        withAnimation(.spring(duration: 0.3)) {
            items = meal.items.map { (id: UUID(), product: $0.asBarcodeProduct, quantity: $0.quantity) }
            builderMode = .build
        }

        meal.lastUsedAt = .now
    }
}
