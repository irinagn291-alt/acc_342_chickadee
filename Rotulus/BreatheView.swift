import SwiftUI

/// Timed breathe step. Skip writes a Waft through the session.
/// Cue text follows `Cue.at(elapsed)`.

struct BreatheView: View {
    var session: RitualSession
    var onDone: () -> Void
    @State private var started = Date()
    @ScaledMetric(relativeTo: .largeTitle) private var numberSize: CGFloat = 84

    var body: some View {
        TimelineView(.periodic(from: started, by: 1)) { context in
            let elapsed = max(0, context.date.timeIntervalSince(started))
            let total = session.record.breatheSeconds
            let remaining = max(0, total - elapsed)
            let cue = Cue.at(min(elapsed, total))
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s24) {
                    StatusCaption(text: "Breathe. \(cueWord(cue)).")
                    Text(remaining, format: .number.precision(.fractionLength(0)))
                        .font(TypeScale.number(size: numberSize))
                        .monospacedDigit()
                        .foregroundStyle(DesignTokens.accent)
                        .contentTransition(.numericText(value: remaining))
                        .animation(Motion.state, value: Int(remaining))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("Seconds left")
                        .accessibilityValue(Text(remaining, format: .number.precision(.fractionLength(0))))
                    Plate {
                        VStack(alignment: .leading, spacing: Spacing.s8) {
                            Text(cueWord(cue))
                                .font(TypeScale.chip)
                                .tracking(1.2)
                                .textCase(.uppercase)
                                .foregroundStyle(DesignTokens.ink)
                            Text(remaining > 0 ? "Stay with the count." : "Count finished.")
                                .font(TypeScale.body)
                                .foregroundStyle(DesignTokens.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Button("Skip this chamber", action: skip)
                        .buttonStyle(QuietTextButtonStyle())
                        .disabled(!canSkip)
                }
                .padding(Spacing.s24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(DesignTokens.bg)
        }
        .navigationTitle("Breathe")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var canSkip: Bool {
        let surface = RitualSurface.make(
            record: session.record,
            notice: session.notice,
            refusal: session.refusal
        )
        return surface.canWaft
    }

    private func skip() {
        session.waft()
        onDone()
    }

    private func cueWord(_ cue: Cue) -> String {
        switch cue {
        case .settle: "Settle"
        case .draw: "Draw"
        case .release: "Release"
        case .rest: "Rest"
        }
    }
}
