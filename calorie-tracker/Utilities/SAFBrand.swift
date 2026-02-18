import SwiftUI

// MARK: - Brand Color

extension Color {
    static let safOrange = Color(red: 1.0, green: 107.0 / 255.0, blue: 53.0 / 255.0)
}

// MARK: - SAF Logo (vector, renders at any size)

struct SAFLogo: View {
    var size: CGFloat = 80

    var body: some View {
        Canvas { context, canvas in
            let s = canvas.width

            // Proportions from the 1024×1024 master design
            let bar = s * 76.0 / 1024.0
            let lw  = s * 250.0 / 1024.0
            let lh  = s * 460.0 / 1024.0
            let gap = s * 40.0 / 1024.0

            let totalW = lw * 3 + gap * 2
            let x0 = (s - totalW) / 2
            let y0 = (s - lh) / 2

            func fill(_ rect: CGRect, _ color: Color) {
                context.fill(Path(rect), with: .color(color))
            }

            let w = Color.white
            let a = Color.safOrange

            // ── S ──
            let sx = x0
            fill(CGRect(x: sx, y: y0, width: lw, height: bar), w)
            fill(CGRect(x: sx, y: y0, width: bar, height: lh / 2 + bar / 2), w)
            fill(CGRect(x: sx, y: y0 + lh / 2 - bar / 2, width: lw, height: bar), w)
            fill(CGRect(x: sx + lw - bar, y: y0 + lh / 2 - bar / 2, width: bar, height: lh / 2 + bar / 2), w)
            fill(CGRect(x: sx, y: y0 + lh - bar, width: lw, height: bar), w)

            // ── A ──
            let ax = x0 + lw + gap
            fill(CGRect(x: ax, y: y0, width: lw, height: bar), w)              // top
            fill(CGRect(x: ax, y: y0, width: bar, height: lh), w)              // left leg
            fill(CGRect(x: ax + lw - bar, y: y0, width: bar, height: lh), w)   // right leg
            fill(CGRect(x: ax + bar, y: y0 + lh / 2 - bar / 2,
                         width: lw - bar * 2, height: bar), a)                 // orange crossbar

            // ── F ──
            let fx = x0 + (lw + gap) * 2
            fill(CGRect(x: fx, y: y0, width: bar, height: lh), w)              // stem
            fill(CGRect(x: fx, y: y0, width: lw, height: bar), w)              // top
            fill(CGRect(x: fx, y: y0 + lh / 2 - bar / 2,
                         width: lw * 0.72, height: bar), w)                    // middle (shorter)
        }
        .frame(width: size, height: size)
        .background(Color(white: 0.067))
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }
}
