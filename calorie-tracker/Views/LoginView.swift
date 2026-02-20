import SwiftUI
import AuthenticationServices
import CryptoKit

// MARK: - Particle model

private struct SparkleParticle: Identifiable {
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var rotation: Double
}

// MARK: - Apple Sign-In coordinator (imperative flow, no UIKit button hacks)

private final class AppleSignInCoordinator: NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding {

    var currentNonce: String?
    var onSuccess: (String, String, PersonNameComponents?) -> Void = { _, _, _ in }
    var onError: (Error) -> Void = { _ in }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .windows.first(where: \.isKeyWindow) ?? UIWindow()
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        guard
            let cred      = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = cred.identityToken,
            let token     = String(data: tokenData, encoding: .utf8),
            let nonce     = currentNonce
        else { return }
        onSuccess(token, nonce, cred.fullName)
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error) {
        onError(error)
    }
}

// MARK: - LoginView

struct LoginView: View {
    @Environment(AuthService.self) private var authService

    // ── Intro animation states ─────────────────────────────────────────────
    @State private var iconScale: CGFloat  = 0.04
    @State private var iconRotation: Double = 28.0
    @State private var iconOpacity: Double = 0
    @State private var bloomScale: CGFloat  = 0.3
    @State private var bloomOpacity: Double = 0
    @State private var textOffset: CGFloat  = 26
    @State private var textOpacity: Double  = 0
    @State private var buttonOffset: CGFloat = 34
    @State private var buttonOpacity: Double = 0

    // ── Idle loop states ───────────────────────────────────────────────────
    @State private var glowRadius: CGFloat = 18
    @State private var glowOpacity: Double = 0.30
    @State private var bloomPull: Double   = 0.30   // animates the blur bloom shape

    // ── Background particles ───────────────────────────────────────────────
    @State private var particles: [SparkleParticle] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // ── Background ─────────────────────────────────────────────
                Color(red: 0.04, green: 0.04, blue: 0.09)
                    .ignoresSafeArea()

                // Soft radial glow behind the icon
                RadialGradient(
                    colors: [
                        Color(red: 0.10, green: 0.18, blue: 0.55).opacity(0.40),
                        .clear
                    ],
                    center: .center,
                    startRadius: 10,
                    endRadius: geo.size.height * 0.40
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

                // ── Floating sparkle particles ─────────────────────────────
                ForEach(particles) { p in
                    SparkleShape()
                        .fill(.white.opacity(p.opacity))
                        .frame(width: p.size, height: p.size)
                        .rotationEffect(.degrees(p.rotation))
                        .position(x: p.x, y: p.y)
                        .allowsHitTesting(false)
                }

                // ── Main content ───────────────────────────────────────────
                VStack(spacing: 0) {
                    Spacer()

                    // Icon + bloom layers
                    ZStack {
                        // Wide breathing bloom (arm shape animates)
                        SparkleShape(pull: bloomPull)
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(red: 0.18, green: 0.40, blue: 1.0),
                                        Color(red: 0.08, green: 0.20, blue: 0.72)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 52
                                )
                            )
                            .frame(width: 120, height: 120)
                            .blur(radius: 38)
                            .scaleEffect(bloomScale * 1.45)
                            .opacity(bloomOpacity * 0.65)

                        // Medium glow (AppIcon blurred)
                        AppIcon(size: 120)
                            .blur(radius: 22)
                            .scaleEffect(bloomScale * 1.12)
                            .opacity(bloomOpacity * 0.45)

                        // Crisp icon
                        AppIcon(size: 120)
                            .scaleEffect(iconScale)
                            .rotationEffect(.degrees(iconRotation))
                            .opacity(iconOpacity)
                            .shadow(
                                color: Color(red: 0.15, green: 0.35, blue: 1.0)
                                    .opacity(glowOpacity),
                                radius: glowRadius
                            )
                    }
                    .padding(.bottom, 40)

                    // Title & subtitle
                    VStack(spacing: 8) {
                        Text("Calorie Tracker")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Track your nutrition and\nreach your health goals.")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.52))
                            .multilineTextAlignment(.center)
                    }
                    .offset(y: textOffset)
                    .opacity(textOpacity)

                    Spacer()

                    if let errorMessage = authService.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                    }

                    // Liquid glass Apple button
                    LiquidGlassAppleButton(authService: authService)
                        .padding(.horizontal, 32)
                        .offset(y: buttonOffset)
                        .opacity(buttonOpacity)

                    Spacer().frame(height: 56)
                }
                .padding(.horizontal, 24)
            }
            .onAppear {
                runIntroAnimation()
                scheduleParticles(in: geo.size)
            }
        }
    }

    // MARK: - Animation

    private func runIntroAnimation() {
        // 1 · Bloom materialises
        withAnimation(.easeOut(duration: 0.65).delay(0.10)) {
            bloomScale   = 1.0
            bloomOpacity = 1.0
        }

        // 2 · Icon springs in with a slight counter-clockwise settle
        withAnimation(.spring(response: 0.52, dampingFraction: 0.66).delay(0.28)) {
            iconScale    = 1.0
            iconRotation = 0.0
            iconOpacity  = 1.0
        }

        // 3 · Text rises
        withAnimation(.easeOut(duration: 0.48).delay(0.76)) {
            textOffset  = 0
            textOpacity = 1.0
        }

        // 4 · Button rises
        withAnimation(.spring(response: 0.48, dampingFraction: 0.74).delay(0.96)) {
            buttonOffset  = 0
            buttonOpacity = 1.0
        }

        // 5 · Idle glow pulse starts after icon settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                glowRadius  = 32
                glowOpacity = 0.68
            }
        }

        // 6 · Bloom arm breathing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                bloomPull = 0.18
            }
        }
    }

    // MARK: - Particles

    private func scheduleParticles(in size: CGSize) {
        // Seed a few immediately
        for _ in 0..<5 { spawnParticle(in: size) }

        // Add one every ~0.9 s, keep it lightweight
        Timer.scheduledTimer(withTimeInterval: 0.9, repeats: true) { _ in
            guard particles.count < 14 else { return }
            spawnParticle(in: size)
        }
    }

    private func spawnParticle(in size: CGSize) {
        let id = UUID()
        let p = SparkleParticle(
            id: id,
            x: .random(in: 20...(size.width  - 20)),
            y: .random(in: 60...(size.height - 80)),
            size: .random(in: 4...11),
            opacity: 0,
            rotation: .random(in: 0..<360)
        )
        particles.append(p)

        let targetAlpha = Double.random(in: 0.04...0.16)
        let lifetime    = Double.random(in: 1.6...3.4)

        withAnimation(.easeIn(duration: 0.45)) {
            updateParticle(id: id) { $0.opacity = targetAlpha }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + lifetime) {
            withAnimation(.easeOut(duration: 0.55)) {
                updateParticle(id: id) { $0.opacity = 0 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                particles.removeAll { $0.id == id }
            }
        }
    }

    private func updateParticle(id: UUID, mutation: (inout SparkleParticle) -> Void) {
        guard let i = particles.firstIndex(where: { $0.id == id }) else { return }
        mutation(&particles[i])
    }
}

// MARK: - Liquid Glass Apple Button

private struct LiquidGlassAppleButton: View {
    let authService: AuthService

    @State private var coordinator = AppleSignInCoordinator()

    var body: some View {
        Button(action: triggerSignIn) {
            ZStack {
                // ── Glass substrate ────────────────────────────────────────
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)

                // Inner gradient shimmer
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.14), .white.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Specular edge highlight
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.50),
                                .white.opacity(0.12),
                                .white.opacity(0.04)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )

                // ── Label ──────────────────────────────────────────────────
                HStack(spacing: 8) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Sign in with Apple")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.white)
            }
            .frame(height: 56)
        }
        .buttonStyle(GlassPressStyle())
        .shadow(color: .black.opacity(0.30), radius: 20, x: 0, y: 8)
        .onAppear {
            coordinator.onSuccess = { token, nonce, fullName in
                Task { await authService.signInWithApple(idToken: token, nonce: nonce, fullName: fullName) }
            }
            coordinator.onError = { error in
                if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                    authService.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func triggerSignIn() {
        let nonce = randomNonceString()
        coordinator.currentNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email, .fullName]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = coordinator
        controller.presentationContextProvider = coordinator
        controller.performRequests()
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        precondition(errorCode == errSecSuccess, "Failed to generate nonce")
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Press scale button style

private struct GlassPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.965 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.70), value: configuration.isPressed)
    }
}
