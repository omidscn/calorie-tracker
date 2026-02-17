import SwiftUI

struct EntryInputBar: View {
    @Binding var inputText: String
    @Binding var selectedMealType: MealType
    @Binding var aiEnabled: Bool
    var onSubmit: () -> Void
    var onBarcodeTap: () -> Void = {}
    var isProcessing: Bool

    private var hasText: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        HStack(spacing: 12) {
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
                    #endif
                }
            } label: {
                Image(systemName: selectedMealType.icon)
                    .font(.title3)
                    .frame(width: 48, height: 48)
                    .contentShape(.circle)
                    .clipShape(.circle)
                    .glassEffect(.regular.interactive(), in: .circle)
            }

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
                .disabled(isProcessing)

                if isProcessing {
                    ProgressView()
                        .controlSize(.small)
                } else if hasText {
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
    }
}
