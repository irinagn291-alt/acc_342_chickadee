import SwiftUI

/// Sealed nights, newest first. Empty, failed, and filled each have a page.
/// Selecting a night pushes a read-only page. This view does not seal anything.

struct HistoryView: View {
    var session: RitualSession
    var onSelect: (Int) -> Void
    var onBegin: () -> Void
    var onRetry: () -> Void

    private var surface: HistorySurface {
        HistorySurface.make(record: session.record, notice: session.notice)
    }

    var body: some View {
        Group {
            switch surface.load {
            case .failed(let message):
                failed(message)
            case .empty:
                emptyPage
            case .populated:
                list
            }
        }
        .background(DesignTokens.bg)
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var list: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s16) {
                if let first = surface.nights.first {
                    nightButton(first, hero: true)
                }
                ForEach(surface.nights.dropFirst()) { night in
                    nightButton(night, hero: false)
                }
            }
            .padding(Spacing.s24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func nightButton(_ night: NightMark, hero: Bool) -> some View {
        Button {
            onSelect(night.dayKey)
        } label: {
            VStack(alignment: .leading, spacing: Spacing.s12) {
                dayLabel(night.dayKey)
                    .font(hero ? TypeScale.callout : TypeScale.body)
                    .foregroundStyle(DesignTokens.ink)
                    .lineLimit(1)
                strip("Reflect", night.reflect)
                strip("Breathe", night.breathe)
                strip("Ambient", night.ambient)
            }
            .padding(Spacing.s16)
            .frame(maxWidth: .infinity, minHeight: Measure.hit, alignment: .leading)
            .background(DesignTokens.surface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .lifted()
            .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
        .buttonStyle(PressCardStyle())
    }

    private var emptyPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s24) {
                Image("rtl_EmptyRiteArt")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: Measure.art)
                    .padding(Spacing.s16)
                    .background(DesignTokens.surface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                    .lifted()
                    .accessibilityHidden(true)
                Text(HistorySurface.emptyTitle)
                    .font(TypeScale.callout)
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: Spacing.s24)
                Button(HistorySurface.beginTitle, action: onBegin)
                    .buttonStyle(SoftCardButtonStyle(accent: true))
            }
            .padding(Spacing.s24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .containerRelativeFrame(.vertical)
        }
    }

    private func failed(_ message: String) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s16) {
                StatusCaption(text: "History failed")
                Text("Load failed. Try again.")
                    .font(TypeScale.callout)
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(message)
                    .font(TypeScale.body)
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Retry", action: onRetry)
                    .buttonStyle(SoftCardButtonStyle(accent: true))
            }
            .padding(Spacing.s24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func strip(_ name: String, _ value: String?) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text(name)
                .font(TypeScale.chip)
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(DesignTokens.muted)
                .lineLimit(1)
            Text(shown(value))
                .font(TypeScale.body)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.s12)
        .frame(maxWidth: .infinity, minHeight: Measure.hit, alignment: .leading)
        .background(DesignTokens.bg, in: RoundedRectangle(cornerRadius: Radius.chip, style: .continuous))
    }

    private func shown(_ value: String?) -> String {
        if let value, !value.isEmpty { return value }
        return "Skipped"
    }

    @ViewBuilder
    private func dayLabel(_ key: Int) -> some View {
        if let date = DayKey.date(from: key, calendar: .current) {
            Text(date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
        } else {
            Text("unknown")
        }
    }
}
