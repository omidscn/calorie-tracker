import SwiftUI

struct ForceUpdateView: View {
    let message: String
    let storeUrl: String

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.09)
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(red: 0.10, green: 0.18, blue: 0.55).opacity(0.40),
                    .clear
                ],
                center: .center,
                startRadius: 10,
                endRadius: 280
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                AppIcon(size: 100)

                VStack(spacing: 12) {
                    Text("Update Required")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    if !message.isEmpty {
                        Text(message)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }

                Button {
                    if let url = URL(string: storeUrl), !storeUrl.isEmpty {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Update Now")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 30/255, green: 79/255, blue: 216/255),
                                    Color(red: 9/255,  green: 21/255, blue: 64/255)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(storeUrl.isEmpty)
                .padding(.horizontal, 32)
            }
        }
    }
}
