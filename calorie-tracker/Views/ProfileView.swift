import SwiftUI
import SwiftData
import Charts
import Auth

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeightEntry.timestamp, order: .reverse) private var weightEntries: [WeightEntry]
    @Query(sort: \FoodEntry.timestamp, order: .reverse) private var allFoodEntries: [FoodEntry]

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

    private var weeksToGoal: Int? {
        TDEECalculator.weeksToTarget(currentKg: currentWeightKg, targetKg: userTargetWeightKg, weeklyChangeKg: weeklyChange)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                weightSection
                weightChartSection
                streakSection
                projectionSection
                calorieGoalSection
                accountSection
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scrollContentBackground(.hidden)
        .navigationTitle("Profile")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onTapGesture {
            commitWeight()
            #if os(iOS)
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            #endif
        }
        .sheet(isPresented: $showRecalculate) {
            RecalculateView()
        }
        .onChange(of: showRecalculate) {
            if !showRecalculate {
                sliderCalories = Double(dailyCalorieGoal)
            }
        }
        .onAppear {
            sliderCalories = Double(dailyCalorieGoal)
            weightValue = currentWeightKg
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

    // MARK: - Calorie Streak (Contribution Graph)

    private var streakSection: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let totalWeeks = 12
        let totalDays = totalWeeks * 7

        // Build lookup of daily calories
        let caloriesByDay: [Date: Int] = {
            var dict: [Date: Int] = [:]
            for entry in allFoodEntries {
                let day = calendar.startOfDay(for: entry.timestamp)
                dict[day, default: 0] += entry.calories
            }
            return dict
        }()

        // Build grid: 7 rows (Mon-Sun) x 12 columns (weeks)
        // Find the start: go back totalDays from today, then align to Monday
        let rawStart = calendar.date(byAdding: .day, value: -(totalDays - 1), to: today)!
        let weekday = calendar.component(.weekday, from: rawStart)
        // weekday: 1=Sun, 2=Mon, ...
        let mondayOffset = weekday == 1 ? -6 : (2 - weekday)
        let gridStart = calendar.date(byAdding: .day, value: mondayOffset, to: rawStart)!

        let gridColumns = ((calendar.dateComponents([.day], from: gridStart, to: today).day ?? 0) + 7) / 7

        // Count streak and stats
        let daysOnGoal = caloriesByDay.values.filter { $0 > 0 && $0 <= dailyCalorieGoal }.count
        let daysTracked = caloriesByDay.values.filter { $0 > 0 }.count

        return VStack(spacing: 12) {
            HStack {
                Text("Calorie Streak")
                    .font(.headline)
                Spacer()

                if daysTracked > 0 {
                    Text("\(daysOnGoal)/\(daysTracked) days on goal")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            // Month labels
            HStack(spacing: 0) {
                // Spacer for day labels
                Color.clear.frame(width: 22)

                let monthLabels = buildMonthLabels(gridStart: gridStart, columns: gridColumns, calendar: calendar)
                ForEach(monthLabels, id: \.offset) { label in
                    if label.offset > 0 {
                        Spacer().frame(minWidth: 0)
                    }
                    Text(label.name)
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                    if label.offset < monthLabels.count - 1 {
                        Spacer().frame(minWidth: 0)
                    }
                }
                Spacer()
            }

            HStack(alignment: .top, spacing: 3) {
                // Day-of-week labels
                VStack(spacing: 3) {
                    ForEach(0..<7, id: \.self) { row in
                        if row == 0 || row == 2 || row == 4 || row == 6 {
                            Text(shortDayName(row))
                                .font(.system(size: 9))
                                .foregroundStyle(.tertiary)
                                .frame(width: 18, height: 12)
                        } else {
                            Color.clear.frame(width: 18, height: 12)
                        }
                    }
                }

                // Grid of cells
                HStack(spacing: 3) {
                    ForEach(0..<gridColumns, id: \.self) { col in
                        VStack(spacing: 3) {
                            ForEach(0..<7, id: \.self) { row in
                                let dayOffset = col * 7 + row
                                let date = calendar.date(byAdding: .day, value: dayOffset, to: gridStart)!
                                let cals = caloriesByDay[calendar.startOfDay(for: date)]
                                let isFuture = date > today

                                RoundedRectangle(cornerRadius: 2.5)
                                    .fill(cellColor(calories: cals, goal: dailyCalorieGoal, isFuture: isFuture))
                                    .frame(height: 12)
                            }
                        }
                    }
                }
            }

            // Legend
            HStack(spacing: 4) {
                Spacer()
                Text("Less")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)

                ForEach(legendColors, id: \.self) { color in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: 10, height: 10)
                }

                Text("More")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var legendColors: [Color] {
        [
            .secondary.opacity(0.15),
            .red.opacity(0.6),
            .orange.opacity(0.6),
            .green.opacity(0.35),
            .green.opacity(0.7)
        ]
    }

    private func cellColor(calories: Int?, goal: Int, isFuture: Bool) -> Color {
        if isFuture { return .secondary.opacity(0.06) }
        guard let cals = calories, cals > 0 else { return .secondary.opacity(0.15) }

        let ratio = Double(cals) / Double(goal)
        if ratio <= 0.75 {
            return .green.opacity(0.35) // well under
        } else if ratio <= 1.0 {
            return .green.opacity(0.7) // on target
        } else if ratio <= 1.15 {
            return .orange.opacity(0.6) // slightly over
        } else {
            return .red.opacity(0.6) // significantly over
        }
    }

    private func shortDayName(_ row: Int) -> String {
        // Mon=0, Tue=1, ..., Sun=6
        let names = ["M", "T", "W", "T", "F", "S", "S"]
        return names[row]
    }

    private struct MonthLabel: Identifiable {
        let name: String
        let offset: Int
        var id: Int { offset }
    }

    private func buildMonthLabels(gridStart: Date, columns: Int, calendar: Calendar) -> [MonthLabel] {
        var labels: [MonthLabel] = []
        var lastMonth = -1
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        for col in 0..<columns {
            let date = calendar.date(byAdding: .day, value: col * 7, to: gridStart)!
            let month = calendar.component(.month, from: date)
            if month != lastMonth {
                labels.append(MonthLabel(name: formatter.string(from: date), offset: col))
                lastMonth = month
            }
        }
        return labels
    }

    // MARK: - Weight Projection

    private var projectionSection: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Projection")
                    .font(.headline)
                Spacer()
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f", currentWeightKg))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("kg")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(spacing: 6) {
                    let gaining = weeklyChange > 0.01
                    let losing = weeklyChange < -0.01
                    Image(systemName: losing || gaining ? "arrow.right" : "equal")
                        .font(.title2)
                        .foregroundStyle(.tertiary)

                    if let weeks = weeksToGoal {
                        Text(TDEECalculator.formatDuration(weeks: weeks))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if abs(currentWeightKg - userTargetWeightKg) < 0.5 {
                        Text("At goal!")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.green)
                    } else {
                        Text("Adjust goal")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Target")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f", userTargetWeightKg))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("kg")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let weeks = weeksToGoal {
                let targetDate = Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: .now)!
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                    Text("Estimated: \(targetDate.formatted(.dateTime.month(.wide).year()))")
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
            } else if abs(currentWeightKg - userTargetWeightKg) < 0.5 {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("You're at your goal weight!")
                        .font(.subheadline)
                }
                .foregroundStyle(.green)
            }

            // Warning for extreme deficit/surplus
            let weeklyKg = weeklyChange
            if weeklyKg < -1.0 {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text("Losing more than 1 kg/week may be unsustainable")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .glassEffect(.regular, in: .rect(cornerRadius: 10))
            } else if weeklyKg > 1.0 {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text("Gaining more than 1 kg/week may lead to excess fat gain")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .glassEffect(.regular, in: .rect(cornerRadius: 10))
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

            let weeklyKg = weeklyChange
            HStack(spacing: 6) {
                Image(systemName: "scalemass")
                if abs(weeklyKg) < 0.05 {
                    Text("Weight stable")
                        .font(.subheadline)
                } else {
                    Text(String(format: "%+.2f kg / week", weeklyKg))
                        .font(.subheadline.monospacedDigit())
                }
            }
            .foregroundStyle(.secondary)

            Button {
                showRecalculate = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Recalculate from scratch")
                }
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .glassEffect(.regular.interactive(), in: .capsule)
            }
            .padding(.top, 4)
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
