import SwiftUI

/// Spacing, type, radius, elevation, and press treatment.
/// Views reach colour through `DesignTokens` and these accessors only.

enum Spacing {
    static let s4: CGFloat = 4
    static let s8: CGFloat = 8
    static let s12: CGFloat = 12
    static let s16: CGFloat = 16
    static let s20: CGFloat = 20
    static let s24: CGFloat = 24
    static let s32: CGFloat = 32
    static let s40: CGFloat = 40
    static let s48: CGFloat = 48
}

enum Measure {
    static let hit: CGFloat = 44
    static let column: CGFloat = 320
    static let side: CGFloat = 240
    static let dither: CGFloat = 220
    static let art: CGFloat = 180
}

enum Radius {
    static let card: CGFloat = 18
    static let chip: CGFloat = 8
}

enum Motion {
    static let press = Animation.easeOut(duration: 0.16)
    static let sheet = Animation.easeOut(duration: 0.16)
    static let state = Animation.spring(.snappy)
}

enum TypeScale {
    static func display(size: CGFloat) -> Font {
        Font.custom(DesignTokens.fontFamily, size: size, relativeTo: .largeTitle).bold()
    }

    static func number(size: CGFloat) -> Font {
        Font.custom(DesignTokens.fontFamily, size: size, relativeTo: .title)
    }

    static let body = Font.custom(DesignTokens.fontFamily, size: 17, relativeTo: .body)
    static let callout = Font.custom(DesignTokens.fontFamily, size: 20, relativeTo: .title3)
    static let caption = Font.custom(DesignTokens.fontFamily, size: 13, relativeTo: .caption)
    static let chip = Font.custom(DesignTokens.fontFamily, size: 12, relativeTo: .caption2)
}

struct Lift: ViewModifier {
    func body(content: Content) -> some View {
        content.shadow(color: Color.black.opacity(0.28), radius: 12, x: 0, y: Spacing.s8)
    }
}

extension View {
    func lifted() -> some View {
        modifier(Lift())
    }
}

struct SoftCardButtonStyle: ButtonStyle {
    var accent: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        SoftCardLabel(accent: accent, configuration: configuration)
    }
}

private struct SoftCardLabel: View {
    var accent: Bool
    let configuration: ButtonStyleConfiguration
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        configuration.label
            .font(TypeScale.body)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: Measure.hit)
            .padding(.horizontal, Spacing.s16)
            .background(fill, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(DesignTokens.muted, lineWidth: isEnabled && accent ? 0 : 1)
            }
            .lifted()
            .scaleEffect(pressedScale)
            .opacity(pressedOpacity)
            .animation(Motion.press, value: configuration.isPressed)
            .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    private var fill: Color {
        if !isEnabled { return DesignTokens.surface }
        return accent ? DesignTokens.accent : DesignTokens.surface
    }

    private var foreground: Color {
        if !isEnabled { return DesignTokens.muted }
        return accent ? DesignTokens.bg : DesignTokens.ink
    }

    private var pressedScale: CGFloat {
        if reduceMotion || !isEnabled || !configuration.isPressed { return 1 }
        return 0.97
    }

    private var pressedOpacity: Double {
        if reduceMotion && configuration.isPressed && isEnabled { return 0.72 }
        return 1
    }
}

struct StatusCaption: View {
    var text: String

    var body: some View {
        Text(text)
            .font(TypeScale.caption)
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundStyle(DesignTokens.muted)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SheetEntrance: ViewModifier {
    var instant: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var arrived: Bool

    init(instant: Bool) {
        self.instant = instant
        _arrived = State(initialValue: instant)
    }

    func body(content: Content) -> some View {
        content
            .opacity(arrived ? 1 : 0)
            .scaleEffect(reduceMotion || instant ? 1 : (arrived ? 1 : 0.96))
            .animation(instant ? nil : Motion.sheet, value: arrived)
            .onAppear { arrived = true }
    }
}

/// Quiet text exit under a filled primary. Full-width hit, no SoftCard fill.
struct QuietTextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        QuietTextLabel(configuration: configuration)
    }
}

private struct QuietTextLabel: View {
    let configuration: ButtonStyleConfiguration
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        configuration.label
            .font(TypeScale.caption)
            .foregroundStyle(isEnabled ? DesignTokens.muted : DesignTokens.muted.opacity(0.5))
            .frame(maxWidth: .infinity, minHeight: Measure.hit, alignment: .leading)
            .contentShape(Rectangle())
            .opacity(reduceMotion && configuration.isPressed && isEnabled ? 0.72 : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

struct PressCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PressCardBody(configuration: configuration)
    }
}

private struct PressCardBody: View {
    let configuration: ButtonStyleConfiguration
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        configuration.label
            .scaleEffect(reduceMotion || !configuration.isPressed ? 1 : 0.97)
            .opacity(reduceMotion && configuration.isPressed ? 0.72 : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

struct Plate<Content: View>: View {
    var chip: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(chip ? Spacing.s12 : Spacing.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignTokens.surface, in: RoundedRectangle(cornerRadius: chip ? Radius.chip : Radius.card, style: .continuous))
            .lifted()
    }
}
