import SwiftUI

// MARK: - Sparkle Shape

/// A 4-pointed ✦ star with concave bezier sides, fitting its bounding rect.
struct SparkleShape: Shape {
    var pull: Double = 0.30

    var animatableData: Double {
        get { pull }
        set { pull = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        let s  = min(rect.width, rect.height) / 2

        let tipR   = s * 0.940
        let waistR = s * 0.303

        var verts: [CGPoint] = []
        for i in 0..<8 {
            let ang = CGFloat(i) * .pi / 4
            let r   = i % 2 == 0 ? tipR : waistR
            verts.append(CGPoint(
                x: cx + r * sin(ang),
                y: cy - r * cos(ang)
            ))
        }

        var path = Path()
        for i in 0..<8 {
            let p0 = verts[i]
            let p3 = verts[(i + 1) % 8]

            let lcp1 = CGPoint(x: p0.x * 0.65 + p3.x * 0.35,
                               y: p0.y * 0.65 + p3.y * 0.35)
            let lcp2 = CGPoint(x: p0.x * 0.35 + p3.x * 0.65,
                               y: p0.y * 0.35 + p3.y * 0.65)

            let f = CGFloat(pull)
            let cp1 = CGPoint(x: lcp1.x + (cx - lcp1.x) * f,
                              y: lcp1.y + (cy - lcp1.y) * f)
            let cp2 = CGPoint(x: lcp2.x + (cx - lcp2.x) * f,
                              y: lcp2.y + (cy - lcp2.y) * f)

            if i == 0 { path.move(to: p0) }
            path.addCurve(to: p3, control1: cp1, control2: cp2)
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Sparkle Particles Background

/// Floating ✦ particles + a subtle green radial glow confined to the top
/// portion of the screen, fading to transparent at the midpoint.
/// Renders **in front of** content at zero hit-testing cost.
struct SparkleParticlesBackground: View {

    private struct Particle: Identifiable {
        let id: UUID
        var x, y, size, opacity, rotation: CGFloat
    }

    @State private var particles: [Particle] = []

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let spawnH = h * 0.48

            ZStack {
                // ── Subtle green radial glow ───────────────────────────────
                RadialGradient(
                    colors: [
                        Color(red: 0.18, green: 0.80, blue: 0.35).opacity(0.32),
                        .clear
                    ],
                    center: UnitPoint(x: 0.5, y: 0.0),
                    startRadius: 0,
                    endRadius: h * 0.55
                )

                // ── Sparkle particles ──────────────────────────────────────
                ForEach(particles) { p in
                    SparkleShape()
                        .fill(Color.white.opacity(p.opacity))
                        .frame(width: p.size, height: p.size)
                        .rotationEffect(.degrees(p.rotation))
                        .position(x: p.x, y: p.y)
                }
            }
            // Fade everything out before the midpoint
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0.0),
                        .init(color: .black, location: 0.30),
                        .init(color: .clear,  location: 0.58),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .allowsHitTesting(false)
            .task {
                for _ in 0..<6 { spawn(w: w, maxY: spawnH) }
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(0.85))
                    if particles.count < 16 { spawn(w: w, maxY: spawnH) }
                }
            }
        }
    }

    private func spawn(w: CGFloat, maxY: CGFloat) {
        let id = UUID()
        particles.append(Particle(
            id: id,
            x: .random(in: 16...(w - 16)),
            y: .random(in: 8...maxY),
            size: .random(in: 5...13),
            opacity: 0,
            rotation: .random(in: 0..<360)
        ))
        let alpha    = CGFloat.random(in: 0.08...0.22)
        let lifetime = Double.random(in: 1.8...3.6)

        withAnimation(.easeIn(duration: 0.45)) { update(id) { $0.opacity = alpha } }
        Task {
            try? await Task.sleep(for: .seconds(lifetime))
            withAnimation(.easeOut(duration: 0.55)) { update(id) { $0.opacity = 0 } }
            try? await Task.sleep(for: .seconds(0.6))
            particles.removeAll { $0.id == id }
        }
    }

    private func update(_ id: UUID, mutation: (inout Particle) -> Void) {
        guard let i = particles.firstIndex(where: { $0.id == id }) else { return }
        mutation(&particles[i])
    }
}

// MARK: - App Icon View

struct AppIcon: View {
    var size: CGFloat = 80

    // Grape circle centres from Lucide SVG (viewBox 0 0 24 24)
    private let circles: [(CGFloat, CGFloat)] = [
        (13.91,  5.85), (8.11,  7.40), (18.15, 10.09), (12.35, 11.65),
        ( 6.56, 13.20), (16.60, 15.89), (10.80, 17.44), ( 5.00, 19.00),
    ]

    var body: some View {
        ZStack {
            // Green gradient background (matches the app icon PNG)
            LinearGradient(
                colors: [
                    Color(red: 96/255,  green: 238/255, blue: 120/255),
                    Color(red: 10/255,  green: 186/255, blue: 60/255),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Grape cluster drawn via Canvas — same scale+centering as the PNG generator:
            //   PNG uses sc=30 for a 1024px canvas, SVG centre (11.5, 12.0) → screen centre.
            //   SwiftUI Canvas: y-down (same as SVG), so no y-flip needed.
            Canvas { ctx, canvasSize in
                let w  = canvasSize.width
                // Replicate PNG ratio: sc/canvasSize = 30/1024
                let sc = w * 30.0 / 1024.0
                // Origin offsets so SVG point (11.5, 12.0) lands at canvas centre
                let ox = w / 2.0 - 11.5 * sc
                let oy = w / 2.0 - 12.0 * sc
                let r  = 3.0 * sc

                // Unified filled path for all 8 grape circles
                var grapePath = Path()
                for (cx, cy) in circles {
                    grapePath.addEllipse(in: CGRect(
                        x: ox + cx * sc - r, y: oy + cy * sc - r,
                        width: r * 2,        height: r * 2))
                }
                ctx.fill(grapePath, with: .color(.white))

                // Vine tendril: M22 5V2l-5.89 5.89
                var vine = Path()
                vine.move(to:    CGPoint(x: ox + 22.00 * sc, y: oy +  5.00 * sc))
                vine.addLine(to: CGPoint(x: ox + 22.00 * sc, y: oy +  2.00 * sc))
                vine.addLine(to: CGPoint(x: ox + 16.11 * sc, y: oy +  7.89 * sc))
                ctx.stroke(vine, with: .color(.white),
                           style: StrokeStyle(lineWidth: sc * 0.52,
                                              lineCap: .round, lineJoin: .round))
            }
            .shadow(color: .black.opacity(0.22), radius: size * 0.025,
                    x: 0, y: size * 0.013)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }
}
