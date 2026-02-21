import SwiftUI

struct SplashView: View {

    @State private var glowRadius: CGFloat = 16
    @State private var glowOpacity: Double = 0.25
    @State private var iconScale: CGFloat = 0.92
    @State private var ringScale: CGFloat = 1.0
    @State private var ringOpacity: Double = 0.0

    var body: some View {
        ZStack {
            // ── Background ─────────────────────────────────────────────────
            Color(red: 0.04, green: 0.04, blue: 0.09)
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(red: 0.18, green: 0.80, blue: 0.35).opacity(0.35),
                    .clear
                ],
                center: .center,
                startRadius: 10,
                endRadius: 280
            )
            .ignoresSafeArea()

            // ── Sparkle particles (top half only) ─────────────────────────
            SparkleParticlesBackground()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // ── Icon + rings ───────────────────────────────────────────────
            ZStack {
                // Expanding ring pulse
                Circle()
                    .strokeBorder(
                        Color(red: 0.30, green: 0.85, blue: 0.45).opacity(ringOpacity),
                        lineWidth: 1.5
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(ringScale)

                // Soft bloom behind icon
                AppIcon(size: 120)
                    .blur(radius: 22)
                    .opacity(0.45)

                // Crisp icon
                AppIcon(size: 120)
                    .scaleEffect(iconScale)
                    .shadow(
                        color: Color(red: 0.30, green: 0.85, blue: 0.45).opacity(glowOpacity),
                        radius: glowRadius
                    )
            }
        }
        .onAppear {
            // Gentle breathing glow
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                glowRadius  = 34
                glowOpacity = 0.70
                iconScale   = 1.0
            }
            // Ring pulse — expands and fades out repeatedly
            withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                ringScale   = 1.55
                ringOpacity = 0.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false).delay(0)) {
                    ringOpacity = 0.38
                }
            }
        }
    }
}
