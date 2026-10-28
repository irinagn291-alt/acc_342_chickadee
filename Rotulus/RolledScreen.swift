import SwiftUI

/// Review frame for a sealed night: cutout, then the three lines.
/// It reads an existing night. It does not roll tonight.

struct RolledScreen: View {
    var night: NightMark?
    @ScaledMetric(relativeTo: .largeTitle) private var displaySize: CGFloat = 44

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s24) {
                StatusCaption(text: night == nil ? "Night. Unknown." : "Night. Sealed.")
                Text(night == nil ? "unknown" : "Sealed")
                    .font(TypeScale.display(size: displaySize))
                    .tracking(-0.5)
                    .foregroundStyle(DesignTokens.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Image("rtl_RolledScrollCutout")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: Measure.art)
                    .padding(Spacing.s16)
                    .background(DesignTokens.surface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                    .lifted()
                    .accessibilityHidden(true)
                if let night {
                    if let date = DayKey.date(from: night.dayKey, calendar: .current) {
                        Text(date, format: .dateTime.month(.wide).day().year())
                            .font(TypeScale.callout)
                            .foregroundStyle(DesignTokens.ink)
                            .lineLimit(1)
                    }
                    line("Reflect", night.reflect)
                    line("Breathe", night.breathe)
                    line("Ambient", night.ambient)
                } else {
                    Text("No sealed night yet.")
                        .font(TypeScale.body)
                        .foregroundStyle(DesignTokens.ink)
                }
            }
            .padding(Spacing.s24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(DesignTokens.bg)
        .navigationTitle("Sealed")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func line(_ name: String, _ value: String?) -> some View {
        Plate(chip: true) {
            VStack(alignment: .leading, spacing: Spacing.s8) {
                StatusCaption(text: name)
                Text(value?.isEmpty == false ? (value ?? "Skipped") : "Skipped")
                    .font(TypeScale.body)
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
