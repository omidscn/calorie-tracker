import SwiftUI

enum ProcessingMode: Equatable {
    case none
    case ai(text: String)
    case barcode
}

struct EntryInputBar: View {
    @Binding var inputText: String
    @Binding var selectedMealType: MealType
    @Binding var aiEnabled: Bool
    var onSubmit: () -> Void
    var onBarcodeTap: () -> Void = {}
    var onMealBuilderTap: () -> Void = {}
    var processingMode: ProcessingMode = .none

    private var hasText: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        HStack(spacing: 12) {
            mealMenuButton

            if case .barcode = processingMode {
                barcodeProcessingCapsule
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.96).combined(with: .opacity),
                        removal: .scale(scale: 0.96).combined(with: .opacity)
                    ))
            } else {
                // Keep inputCapsule (and its TextField) in the hierarchy at all times
                // so the keyboard stays up during AI processing.
                ZStack {
                    inputCapsule

                    if case .ai(let text) = processingMode {
                        aiProcessingCapsule(text: text)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.96).combined(with: .opacity),
                                removal: .scale(scale: 0.96).combined(with: .opacity)
                            ))
                    }
                }
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: processingMode)
    }

    // MARK: - Meal Menu Button

    private var mealMenuButton: some View {
        Menu {
            Section("Meal") {
                ForEach(MealType.allCases, id: \.self) { type in
                    Button {
                        selectedMealType = type
                    } label: {
                        Label(type.rawValue, systemImage: type.icon)
                    }
                }
            }
            Section {
                Button {
                    inputText = ""
                    aiEnabled.toggle()
                } label: {
                    Label(
                        aiEnabled ? "Switch to Manual" : "Switch to AI",
                        systemImage: aiEnabled ? "number" : "sparkles"
                    )
                }
                #if os(iOS)
                Button(action: onBarcodeTap) {
                    Label("Scan Barcode", systemImage: "barcode.viewfinder")
                }
                Button(action: onMealBuilderTap) {
                    Label("Build a Meal", systemImage: "takeoutbag.and.cup.and.straw")
                }
                #endif
            }
        } label: {
            Image(systemName: selectedMealType.icon)
                .font(.title3)
                .frame(width: 48, height: 48)
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .contentShape(.circle)
        .clipShape(.circle)
    }

    // MARK: - Normal Input Capsule

    private var inputCapsule: some View {
        HStack(spacing: 8) {
            if aiEnabled {
                Image(systemName: "sparkles")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
            TextField(
                aiEnabled ? "Describe your food..." : "Food name 500",
                text: $inputText
            )
            .font(.body)
            .textFieldStyle(.plain)
            .submitLabel(.done)
            .onSubmit {
                if hasText { onSubmit() }
            }
            if hasText {
                Button(action: onSubmit) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .padding(.vertical, 14)
        .glassEffect(.regular, in: .capsule)
    }

    // MARK: - AI Processing Capsule

    private func aiProcessingCapsule(text: String) -> some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let phase = (t / 1.4).truncatingRemainder(dividingBy: 1.0)
            let glowOpacity = 0.18 + 0.10 * sin(phase * 2 * .pi)

            HStack(spacing: 12) {
                // Three wave-dancing sparkles
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { i in
                        let dotPhase = (phase + Double(i) / 3.0)
                            .truncatingRemainder(dividingBy: 1.0)
                        let yOffset  = -sin(dotPhase * 2 * .pi) * 5.0
                        let scale    = 0.55 + 0.45 * max(0, sin(dotPhase * 2 * .pi))
                        let opacity  = 0.30 + 0.70 * max(0, sin(dotPhase * 2 * .pi))

                        SparkleShape()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.52, green: 0.75, blue: 1.00),
                                        Color(red: 0.12, green: 0.31, blue: 0.85)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 11, height: 11)
                            .scaleEffect(scale)
                            .offset(y: yOffset)
                            .opacity(opacity)
                    }
                }

                // Label
                VStack(alignment: .leading, spacing: 2) {
                    if !text.isEmpty {
                        Text("\"\(text)\"")
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    Text("Analyzing with AI…")
                        .font(text.isEmpty ? .subheadline : .caption)
                        .foregroundStyle(text.isEmpty ? .primary : .secondary)
                }

                Spacer()
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .padding(.vertical, 14)
            .glassEffect(.regular, in: .capsule)
            .shadow(
                color: Color(red: 0.12, green: 0.31, blue: 0.85).opacity(glowOpacity),
                radius: 18,
                y: 4
            )
        }
    }

    // MARK: - Barcode Processing Capsule

    private var barcodeProcessingCapsule: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let phase = (t / 1.2).truncatingRemainder(dividingBy: 1.0)
            let scanX = phase  // 0…1, left to right
            let glowOpacity = 0.12 + 0.08 * sin(phase * 2 * .pi)

            HStack(spacing: 12) {
                // Barcode icon with animated scan line overlay
                ZStack {
                    Image(systemName: "barcode")
                        .font(.title3)
                        .foregroundStyle(.green.opacity(0.85))

                    // Scan line sweeping left→right
                    GeometryReader { geo in
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .green.opacity(0.9), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * 0.35)
                            .offset(x: geo.size.width * scanX - geo.size.width * 0.18)
                            .clipped()
                    }
                    .frame(width: 26, height: 18)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                .frame(width: 28, height: 22)

                Text("Looking up barcode…")
                    .font(.subheadline)

                Spacer()
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .padding(.vertical, 14)
            .glassEffect(.regular, in: .capsule)
            .shadow(
                color: Color.green.opacity(glowOpacity),
                radius: 16,
                y: 4
            )
        }
    }
}
