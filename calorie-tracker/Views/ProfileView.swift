import SwiftUI
import SwiftData
import Charts
import Auth

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeightEntry.timestamp, order: .reverse) private var weightEntries: [WeightEntry]

    @AppStorage("dailyCalorieGoal") private var dailyCalorieGoal: Int = 2000
    @AppStorage("userBiologicalSex") private var userBiologicalSexRaw: String = "male"
    @AppStorage("userAge") private var userAge: Int = 25
    @AppStorage("userHeightCm") private var userHeightCm: Double = 170.0
    @AppStorage("userWeightKg") private var userWeightKg: Double = 70.0
    @AppStorage("userActivityLevel") private var userActivityLevelRaw: String = "moderatelyActive"
    @AppStorage("userTargetWeightKg") private var userTargetWeightKg: Double = 70.0

    @State private var weightValue: Double = 70.0
    @State private var isEditingWeight = false
    @State private var weightText = ""
    @State private var sliderCalories: Double = 2000
    @State private var showAllWeightEntries = false
    @State private var showRecalculate = false
    @State private var showSignOutConfirmation = false
    @Environment(AuthService.self) private var authService
    @FocusState private var weightFieldFocused: Bool

    private var sex: BiologicalSex {
        BiologicalSex(rawValue: userBiologicalSexRaw) ?? .male
    }
    private var activityLevel: ActivityLevel {
        ActivityLevel(rawValue: userActivityLevelRaw) ?? .moderatelyActive
    }
    private var tdee: Double {
        TDEECalculator.calculateTDEE(sex: sex, weightKg: userWeightKg, heightCm: userHeightCm, age: userAge, activity: activityLevel)
    }
    private var currentWeightKg: Double {
        weightEntries.first?.weight ?? userWeightKg
    }

    private var weeklyChange: Double {
        TDEECalculator.weeklyWeightChangeKg(dailyCalories: dailyCalorieGoal, tdee: tdee)
    }


    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    weightSection
                    weightChartSection
                    calorieGoalSection
                    accountSection

                    Text("SIMPLE AS F** CALORIE TRACKER")
                        .font(.system(size: 10, weight: .bold, design: .default))
                        .foregroundStyle(.secondary)
                        .kerning(1.5)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                }
                .padding()
            }
            .navigationTitle("Profile")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onTapGesture {
                commitWeight()
                #if os(iOS)
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                #endif
            }
            .sheet(isPresented: $showRecalculate) {
                RecalculateView()
                    .presentationDetents([.fraction(0.9)])
            }
            .onChange(of: showRecalculate) {
                if !showRecalculate {
                    sliderCalories = Double(dailyCalorieGoal)
                }
            }
            .scrollContentBackground(.hidden)
            .containerBackground(.clear, for: .navigation)
            .onAppear {
                sliderCalories = Double(dailyCalorieGoal)
                weightValue = currentWeightKg
            }
        }
    }

    // MARK: - Weight

    private var weightSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Weight")
                    .font(.headline)
                Spacer()

                if let latest = weightEntries.first,
                   let previous = weightEntries.dropFirst().first {
                    let diff = latest.weight - previous.weight
                    HStack(spacing: 4) {
                        Image(systemName: diff > 0 ? "arrow.up.right" : diff < 0 ? "arrow.down.right" : "arrow.right")
                        Text(String(format: "%+.1f kg", diff))
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(diff > 0 ? .red : diff < 0 ? .green : .secondary)
                }
            }

            // Stepper-style weight input
            HStack(spacing: 16) {
                Button {
                    withAnimation { weightValue = max(30, weightValue - 0.1) }
                } label: {
                    Image(systemName: "minus")
                        .font(.title3.weight(.medium))
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
                }

                if isEditingWeight {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        TextField("", text: $weightText)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .multilineTextAlignment(.center)
                            .focused($weightFieldFocused)
                            .frame(width: 100)
                            .onChange(of: weightFieldFocused) {
                                if !weightFieldFocused { commitWeight() }
                            }
                        Text("kg")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", weightValue))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text("kg")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        weightText = String(format: "%.1f", weightValue)
                        isEditingWeight = true
                        weightFieldFocused = true
                    }
                }

                Button {
                    withAnimation { weightValue = min(300, weightValue + 0.1) }
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.medium))
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
            }

            // Log button
            Button {
                let entry = WeightEntry(weight: (weightValue * 10).rounded() / 10)
                modelContext.insert(entry)
            } label: {
                Text("Log Weight")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .glassEffect(.regular.interactive(), in: .capsule)
            }

            if !weightEntries.isEmpty {
                let visibleEntries = showAllWeightEntries ? Array(weightEntries) : Array(weightEntries.prefix(2))

                VStack(spacing: 0) {
                    ForEach(visibleEntries) { entry in
                        SwipeToDeleteRow {
                            HStack {
                                Text(entry.timestamp.displayString)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Text(String(format: "%.1f kg", entry.weight))
                                    .font(.body.monospacedDigit())
                                    .fontWeight(.medium)

                                Text(entry.timestamp.shortTimeString)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                        } onDelete: {
                            withAnimation {
                                modelContext.delete(entry)
                            }
                        }

                        if entry.id != visibleEntries.last?.id {
                            Divider()
                        }
                    }

                    if weightEntries.count > 2 {
                        Divider()
                        Button {
                            withAnimation(.snappy) {
                                showAllWeightEntries.toggle()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(showAllWeightEntries ? "Show Less" : "Show More")
                                Image(systemName: showAllWeightEntries ? "chevron.up" : "chevron.down")
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                    }
                }
                .padding(.vertical, 4)
                .glassEffect(.regular, in: .rect(cornerRadius: 12))
                .clipShape(.rect(cornerRadius: 12))
            } else {
                Text("No weight entries yet")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private func commitWeight() {
        if isEditingWeight, let value = Double(weightText), value >= 30, value <= 300 {
            weightValue = value
        }
        isEditingWeight = false
    }

    // MARK: - Weight Chart

    private var chartEntries: [WeightEntry] {
        Array(weightEntries.reversed().suffix(30))
    }

    private var weightChartSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Progress")
                    .font(.headline)
                Spacer()

                if let first = chartEntries.first, let last = chartEntries.last, chartEntries.count > 1 {
                    let diff = last.weight - first.weight
                    Text(String(format: "%+.1f kg", diff))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(diff < 0 ? .green : diff > 0 ? .red : .secondary)
                }
            }

            if chartEntries.count >= 2 {
                let weights = chartEntries.map(\.weight)
                let minW = (weights.min() ?? 60) - 1
                let maxW = (weights.max() ?? 80) + 1

                Chart {
                    ForEach(chartEntries) { entry in
                        AreaMark(
                            x: .value("Date", entry.timestamp),
                            yStart: .value("Min", minW),
                            yEnd: .value("Weight", entry.weight)
                        )
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.green.opacity(0.3), .green.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Date", entry.timestamp),
                            y: .value("Weight", entry.weight)
                        )
                        .foregroundStyle(.green)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", entry.timestamp),
                            y: .value("Weight", entry.weight)
                        )
                        .symbolSize(entry.id == chartEntries.last?.id ? 40 : 20)
                        .foregroundStyle(.green)
                    }

                    if userTargetWeightKg > 0 && userTargetWeightKg >= minW && userTargetWeightKg <= maxW {
                        RuleMark(y: .value("Target", userTargetWeightKg))
                            .foregroundStyle(.secondary.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [6, 4]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("Goal")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                .chartYScale(domain: minW...maxW)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) {
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(.secondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) {
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.secondary.opacity(0.2))
                        AxisValueLabel()
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: 180)
            } else {
                Text("Log at least 2 entries to see your progress chart")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
            }
        }
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }


    // MARK: - Calorie Goal

    private var calorieGoalSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Daily Calorie Goal")
                    .font(.headline)
                Spacer()
                Button {
                    showRecalculate = true
                } label: {
                    Text("Recalculate")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .glassEffect(.regular.interactive(), in: .capsule)
                }
            }

            Text("\(dailyCalorieGoal)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())

            Text("kcal / day")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Slider(
                    value: $sliderCalories,
                    in: 1200...Double(Int(tdee) + 1000),
                    step: 50
                )
                .onChange(of: sliderCalories) {
                    withAnimation(.interactiveSpring) {
                        dailyCalorieGoal = Int(sliderCalories)
                    }
                }

                HStack {
                    Text("1200")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text("TDEE: \(Int(tdee.rounded()))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(tdee) + 1000)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            let deficit = Int(tdee.rounded()) - dailyCalorieGoal
            let weeklyKg = weeklyChange
            HStack(spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: deficit > 0 ? "arrow.down.right" : deficit < 0 ? "arrow.up.right" : "arrow.right")
                    Text(deficit > 0
                         ? "\(deficit) kcal deficit"
                         : deficit < 0
                         ? "\(abs(deficit)) kcal surplus"
                         : "At maintenance")
                        .font(.subheadline)
                }
                .foregroundStyle(deficit > 0 ? .green : deficit < 0 ? .orange : .secondary)

                Spacer()

                if abs(weeklyKg) < 0.05 {
                    Text("Weight stable")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(String(format: "%+.2f kg / week", weeklyKg))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    // MARK: - Account

    private var accountSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Account")
                    .font(.headline)
                Spacer()
            }

            if let email = authService.currentUser?.email {
                HStack {
                    Image(systemName: "envelope")
                        .foregroundStyle(.secondary)
                    Text(email)
                        .font(.subheadline)
                    Spacer()
                }
            }

            Button(role: .destructive) {
                showSignOutConfirmation = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                }
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .glassEffect(.regular.interactive(), in: .capsule)
            }
            .confirmationDialog("Sign Out", isPresented: $showSignOutConfirmation, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    Task { await authService.signOut() }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }
}

// MARK: - Swipe to Delete Row

private struct SwipeToDeleteRow<Content: View>: View {
    @ViewBuilder let content: Content
    let onDelete: () -> Void
    @State private var offset: CGFloat = 0
    @State private var isSwiped = false

    private let deleteWidth: CGFloat = 72

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button — only rendered while swiping
            if offset < 0 {
                Button {
                    withAnimation(.snappy(duration: 0.3)) {
                        onDelete()
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white)
                        .frame(width: deleteWidth)
                        .frame(maxHeight: .infinity)
                        .background(.red)
                }
            }

            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    // Opaque cover only while swiping, so red doesn't bleed through
                    if offset < 0 {
                        Rectangle().fill(.ultraThickMaterial)
                    }
                }
                .offset(x: offset)
                .onTapGesture {
                    if isSwiped {
                        withAnimation(.snappy(duration: 0.3)) {
                            offset = 0
                            isSwiped = false
                        }
                    }
                }
        }
        .clipShape(.rect)
        .contentShape(.rect)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    let translation = value.translation.width
                    if isSwiped {
                        offset = max(min(-deleteWidth + translation, 0), -deleteWidth)
                    } else {
                        offset = min(max(translation, -deleteWidth), 0)
                    }
                }
                .onEnded { value in
                    withAnimation(.snappy(duration: 0.3)) {
                        if isSwiped {
                            if value.translation.width > 30 {
                                offset = 0
                                isSwiped = false
                            } else {
                                offset = -deleteWidth
                            }
                        } else {
                            if value.translation.width < -40 {
                                offset = -deleteWidth
                                isSwiped = true
                            } else {
                                offset = 0
                            }
                        }
                    }
                }
        )
    }
}
