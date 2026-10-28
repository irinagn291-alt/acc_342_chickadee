import SwiftUI

/// The only custom-drawn surface. A procedural dither behind the ambient plate.
/// Type never sits on this raster. No audio files.

struct AmbientDither: View {
    var moving: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if moving && !reduceMotion {
                TimelineView(.animation(minimumInterval: 0.8, paused: false)) { timeline in
                    dots(phase: timeline.date.timeIntervalSinceReferenceDate)
                }
            } else {
                dots(phase: 0)
            }
        }
        .accessibilityHidden(true)
    }

    private func dots(phase: TimeInterval) -> some View {
        Canvas { context, size in
            let step = Spacing.s8
            let shift = Int(phase.truncatingRemainder(dividingBy: 3))
            var row = 0
            var y = Spacing.s4
            while y < size.height {
                var column = 0
                var x = Spacing.s4
                while x < size.width {
                    let band = (row + column + shift) % 5
                    let color: Color
                    switch band {
                    case 0: color = DesignTokens.ink
                    case 1: color = DesignTokens.accent
                    default: color = DesignTokens.muted
                    }
                    let rect = CGRect(x: x, y: y, width: Spacing.s4, height: Spacing.s4)
                    context.fill(Path(ellipseIn: rect), with: .color(color))
                    x += step
                    column += 1
                }
                y += step
                row += 1
            }
        }
        .background(DesignTokens.bg)
    }
}
