import SwiftUI
import HealthKit

struct OnboardingBodyStep: View {
    @Binding var sex: BiologicalSex
    @Binding var age: Int
    @Binding var heightCm: Double
    @Binding var weightKg: Double

    @State private var isEditingAge = false
    @State private var isEditingHeight = false
    @State private var isEditingWeight = false
    @State private var ageText = ""
    @State private var heightText = ""
    @State private var weightText = ""
    @State private var healthImported = false
    @State private var isLoadingHealth = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case age, height, weight
    }

    private let healthService = HealthKitService()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Body Metrics")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .padding(.top, 8)

                if healthService.isAvailable {
                    healthImportButton
                }

                sexCard
                ageCard
                heightCard
                weightCard
            }
            .padding()
        }
        .onTapGesture {
            dismissAll()
        }
    }

    private func dismissAll() {
        focusedField = nil
    }

    // MARK: - Apple Health Import

    private var healthImportButton: some View {
        Button {
            guard !isLoadingHealth else { return }
            isLoadingHealth = true
            Task {
                do {
                    let profile = try await healthService.requestAuthorizationAndRead()
                    withAnimation {
                        if let s = profile.biologicalSex { sex = s }
                        if let a = profile.age { age = a }
                        if let h = profile.heightCm { heightCm = h }
                        if let w = profile.weightKg { weightKg = w }
                        healthImported = true
                    }
                } catch {
                    // Authorization denied or no data — user can enter manually
                }
                isLoadingHealth = false
            }
        } label: {
            HStack(spacing: 10) {
                if isLoadingHealth {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: healthImported ? "checkmark.circle.fill" : "heart.fill")
                        .foregroundStyle(healthImported ? .green : .red)
                }
                Text(healthImported ? "Imported from Health" : "Import from Apple Health")
                    .font(.subheadline.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .glassEffect(.regular.interactive(), in: .capsule)
        }
        .disabled(healthImported)
    }

    // MARK: - Sex

    private var sexCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Biological Sex")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(BiologicalSex.allCases, id: \.self) { option in
                    Button {
                        withAnimation { sex = option }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: option.icon)
                            Text(option.displayName)
                        }
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            sex == option ? Color.accentColor.opacity(0.15) : Color.clear,
                            in: .capsule
                        )
                        .overlay(
                            Capsule()
                                .stroke(sex == option ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: sex == option ? 2 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 20))
    }

    // MARK: - Age

    private var ageCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Age")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Button {
                    withAnimation { age = max(15, age - 1) }
                } label: {
                    Image(systemName: "minus")
                        .font(.title3.weight(.medium))
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
                }

                if isEditingAge {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        TextField("", text: $ageText)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                            .multilineTextAlignment(.center)
                            .focused($focusedField, equals: .age)
                            .frame(width: 80)
                            .onChange(of: focusedField) {
                                if focusedField != .age { commitAge() }
                            }
                        Text("years")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(age)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text("years")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        ageText = "\(age)"
                        isEditingAge = true
                        focusedField = .age
                    }
                }

                Button {
                    withAnimation { age = min(100, age + 1) }
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.medium))
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 20))
    }

    // MARK: - Height

    private var heightCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Height")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Button {
                    withAnimation { heightCm = max(100, heightCm - 1) }
                } label: {
                    Image(systemName: "minus")
                        .font(.title3.weight(.medium))
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
                }

                if isEditingHeight {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        TextField("", text: $heightText)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .multilineTextAlignment(.center)
                            .focused($focusedField, equals: .height)
                            .frame(width: 100)
                            .onChange(of: focusedField) {
                                if focusedField != .height { commitHeight() }
                            }
                        Text("cm")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.0f", heightCm))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text("cm")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        heightText = String(format: "%.0f", heightCm)
                        isEditingHeight = true
                        focusedField = .height
                    }
                }

                Button {
                    withAnimation { heightCm = min(250, heightCm + 1) }
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.medium))
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 20))
    }

    // MARK: - Weight

    private var weightCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Weight")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Button {
                    withAnimation { weightKg = max(30, weightKg - 0.5) }
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
                            .focused($focusedField, equals: .weight)
                            .frame(width: 100)
                            .onChange(of: focusedField) {
                                if focusedField != .weight { commitWeight() }
                            }
                        Text("kg")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", weightKg))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text("kg")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        weightText = String(format: "%.1f", weightKg)
                        isEditingWeight = true
                        focusedField = .weight
                    }
                }

                Button {
                    withAnimation { weightKg = min(300, weightKg + 0.5) }
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.medium))
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 20))
    }

    // MARK: - Helpers

    private func commitAge() {
        if let value = Int(ageText), value >= 15, value <= 100 {
            age = value
        }
        isEditingAge = false
    }

    private func commitHeight() {
        if let value = Double(heightText), value >= 100, value <= 250 {
            heightCm = value
        }
        isEditingHeight = false
    }

    private func commitWeight() {
        if let value = Double(weightText), value >= 30, value <= 300 {
            weightKg = value
        }
        isEditingWeight = false
    }
}
