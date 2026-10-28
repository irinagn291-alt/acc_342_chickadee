import SwiftUI

/// Reflect chamber, read only. The committed line is the page.
/// Opening it does not call `Scroll.apply`.

struct ReflectView: View {
    var session: RitualSession
    var now: Date

    private var scroll: Scroll {
        session.record.aligned(to: now).scroll
    }

    private var line: String {
        let panel = scroll.panels.first { $0.kind == .reflect }
        if let text = panel?.mark?.lineText, !text.isEmpty { return text }
        if panel?.mark != nil { return "Skipped" }
        return "unknown"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s24) {
                StatusCaption(text: "Reflect. \(markWord).")
                Text(line)
                    .font(TypeScale.display(size: displaySize))
                    .tracking(-0.5)
                    .foregroundStyle(DesignTokens.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Plate {
                    VStack(alignment: .leading, spacing: Spacing.s8) {
                        StatusCaption(text: "Next")
                        Text(scroll.focus.displayName)
                            .font(TypeScale.callout)
                            .foregroundStyle(DesignTokens.ink)
                            .lineLimit(1)
                        Text("Return to tonight and commit the open chamber.")
                            .font(TypeScale.body)
                            .foregroundStyle(DesignTokens.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Image("rtl_TwistHero")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: Measure.art)
                    .padding(Spacing.s16)
                    .background(DesignTokens.surface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                    .lifted()
                    .accessibilityHidden(true)
            }
            .padding(Spacing.s24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(DesignTokens.bg)
        .navigationTitle("Reflect")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ScaledMetric(relativeTo: .largeTitle) private var displaySize: CGFloat = 48

    private var markWord: String {
        let panel = scroll.panels.first { $0.kind == .reflect }
        if panel?.isBare == false { return "Marked" }
        return "Bare"
    }
}
