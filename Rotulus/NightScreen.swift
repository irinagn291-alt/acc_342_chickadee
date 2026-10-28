import SwiftUI

/// One sealed night, read only. `spread` unrolls the three lines across the width
/// so the night key is a different frame from the vertical page.

struct NightScreen: View {
    var night: NightMark
    var spread: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s24) {
                StatusCaption(text: "Night. Sealed.")
                dayTitle
                if spread {
                    ViewThatFits(in: .horizontal) {
                        AnyLayout(HStackLayout(alignment: .top, spacing: Spacing.s16)) {
                            strips
                        }
                        AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.s16)) {
                            strips
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: Spacing.s16) {
                        strips
                    }
                }
            }
            .padding(Spacing.s24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(DesignTokens.bg)
        .navigationTitle("Night")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var dayTitle: some View {
        if let date = DayKey.date(from: night.dayKey, calendar: .current) {
            Text(date, format: .dateTime.month(.wide).day().year())
                .font(TypeScale.display(size: displaySize))
                .tracking(-0.5)
                .foregroundStyle(DesignTokens.ink)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text("unknown")
                .font(TypeScale.display(size: displaySize))
                .foregroundStyle(DesignTokens.ink)
        }
    }

    @ScaledMetric(relativeTo: .largeTitle) private var displaySize: CGFloat = 40

    @ViewBuilder
    private var strips: some View {
        strip("Reflect", night.reflect)
        strip("Breathe", night.breathe)
        strip("Ambient", night.ambient)
    }

    private func strip(_ name: String, _ value: String?) -> some View {
        Plate {
            VStack(alignment: .leading, spacing: Spacing.s8) {
                StatusCaption(text: name)
                Text(shown(value))
                    .font(TypeScale.body)
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minWidth: spread ? Measure.side : 0, maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func shown(_ value: String?) -> String {
        if let value, !value.isEmpty { return value }
        return "Skipped"
    }
}
