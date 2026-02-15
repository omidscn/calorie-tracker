import SwiftUI

struct EntryInputBar: View {
    @Binding var inputText: String
    @Binding var selectedMealType: MealType
    @Binding var aiEnabled: Bool
    var onSubmit: () -> Void
    var onBarcodeTap: () -> Void
    var isProcessing: Bool

    var body: some View {
        VStack(spacing: 8) {
            Picker("Meal", selection: $selectedMealType) {
                ForEach(MealType.allCases, id: \.self) { type in
                    Label(type.rawValue, systemImage: type.icon)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 12) {
                TextField(
                    aiEnabled ? "3x Apples, chicken sandwich..." : "Calories (e.g. 500)",
                    text: $inputText
                )
                .frame(minHeight: 44)
                .textFieldStyle(.plain)
                .submitLabel(.done)
                .onSubmit {
                    let trimmed = inputText.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        onSubmit()
                    }
                }
                .disabled(isProcessing)

                if isProcessing {
                    ProgressView()
                        .controlSize(.small)
                }

                Button {
                    inputText = ""
                    aiEnabled.toggle()
                } label: {
                    Text("AI")
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .foregroundStyle(aiEnabled ? Color.blue : Color.gray)
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
                .disabled(isProcessing)

                Button(action: onBarcodeTap) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
                .disabled(isProcessing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }
}
