import SwiftUI

/// Three full-page steps. Continue and Skip both keep the default durations
/// and mark the rite ready. The screen does not write the archive itself.

struct OnboardingView: View {
    var session: RitualSession
    var onFinished: () -> Void
    @State private var step = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var lines: [String] { OnboardingSurface.steps }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s16) {
            TabView(selection: $step) {
                ForEach(Array(lines.enumerated()), id: \.element) { index, line in
                    page(index: index, line: line)
                        .tag(index)
                        .padding(.horizontal, Spacing.s24)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .tint(DesignTokens.accent)
            .animation(reduceMotion ? nil : Motion.sheet, value: step)

            VStack(spacing: Spacing.s12) {
                Button("Skip", action: finish)
                    .buttonStyle(SoftCardButtonStyle(accent: false))
                Button("Continue", action: advance)
                    .buttonStyle(SoftCardButtonStyle(accent: true))
            }
            .padding(.horizontal, Spacing.s24)
            .padding(.bottom, Spacing.s24)
        }
        .background(DesignTokens.bg.ignoresSafeArea())
    }

    private func page(index: Int, line: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s24) {
            Image(artName(index))
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(Spacing.s16)
                .background(DesignTokens.surface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                .lifted()
                .accessibilityHidden(true)
            Text(line)
                .font(TypeScale.callout)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func artName(_ index: Int) -> String {
        switch index {
        case 0: "rtl_Onboarding1"
        case 1: "rtl_Onboarding2"
        default: "rtl_Onboarding3"
        }
    }

    private func advance() {
        if step + 1 < lines.count {
            step += 1
        } else {
            finish()
        }
    }

    private func finish() {
        session.finishOnboarding()
        onFinished()
    }
}
