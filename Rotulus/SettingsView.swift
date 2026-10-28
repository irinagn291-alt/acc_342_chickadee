import SwiftUI

/// Durations, haptics, contact, and reset. Writes only through the session.
/// More than one field, so focus is an enum and the keyboard can move on.

struct SettingsView: View {
    var session: RitualSession
    var onBegin: () -> Void
    var onRetry: () -> Void
    var onReplay: () -> Void
    var onDidReset: () -> Void

    @State private var reflectText: String
    @State private var breatheText: String
    @State private var ambientText: String
    @State private var haptics: Bool
    @State private var confirmReset = false
    @State private var resetting = false
    @FocusState private var focus: Field?

    enum Field: Hashable {
        case reflect
        case breathe
        case ambient
    }

    init(session: RitualSession, onBegin: @escaping () -> Void, onRetry: @escaping () -> Void, onReplay: @escaping () -> Void, onDidReset: @escaping () -> Void) {
        self.session = session
        self.onBegin = onBegin
        self.onRetry = onRetry
        self.onReplay = onReplay
        self.onDidReset = onDidReset
        _reflectText = State(initialValue: Self.display(session.record.reflectSeconds))
        _breatheText = State(initialValue: Self.display(session.record.breatheSeconds))
        _ambientText = State(initialValue: Self.display(session.record.ambientSeconds))
        _haptics = State(initialValue: session.record.hapticsEnabled)
    }

    private var surface: SettingsSurface {
        SettingsSurface.make(record: session.record, notice: session.notice)
    }

    private var isEmpty: Bool {
        session.notice == nil && session.record.nights.isEmpty && session.record.scroll.isUntouched
    }

    var body: some View {
        Group {
            if case .failed(let message) = surface.load {
                failed(message)
            } else if isEmpty {
                empty
            } else {
                form
            }
        }
        .background(DesignTokens.bg)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(SettingsSurface.resetWarning, isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Erase local data", role: .destructive) {
                Task { await erase() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s20) {
                StatusCaption(text: "Pace. Saved on this device.")
                field("Reflect", text: $reflectText, field: .reflect)
                field("Breathe", text: $breatheText, field: .breathe)
                field("Ambient", text: $ambientText, field: .ambient)
                Plate {
                    Toggle("Haptics", isOn: $haptics)
                        .font(TypeScale.body)
                        .foregroundStyle(DesignTokens.ink)
                        .tint(DesignTokens.accent)
                        .frame(minHeight: Measure.hit)
                        .onChange(of: haptics) { _, value in
                            session.setHaptics(value)
                        }
                }
                contact
                Button("Show rite", action: onReplay)
                    .buttonStyle(SoftCardButtonStyle(accent: false))
                Button("Erase local data", action: { confirmReset = true })
                    .buttonStyle(SoftCardButtonStyle(accent: false))
                    .disabled(resetting)
            }
            .padding(Spacing.s24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button("Next") { advance() }
                    .frame(minHeight: Measure.hit)
                Button("Done") { focus = nil }
                    .frame(minHeight: Measure.hit)
            }
        }
        .onTapGesture { focus = nil }
    }

    private var empty: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s24) {
                Image("rtl_EmptyHome")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: Measure.art)
                    .padding(Spacing.s16)
                    .background(DesignTokens.surface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                    .lifted()
                    .accessibilityHidden(true)
                Text("Pace is ready.")
                    .font(TypeScale.callout)
                    .foregroundStyle(DesignTokens.ink)
                Text("Defaults are 90, 120, and 90 seconds.")
                    .font(TypeScale.body)
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Button(HistorySurface.beginTitle, action: onBegin)
                    .buttonStyle(SoftCardButtonStyle(accent: true))
                contact
            }
            .padding(Spacing.s24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func failed(_ message: String) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s16) {
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
                contact
            }
            .padding(Spacing.s24)
        }
    }

    private func field(_ title: String, text: Binding<String>, field: Field) -> some View {
        Plate {
            VStack(alignment: .leading, spacing: Spacing.s8) {
                Text(title)
                    .font(TypeScale.caption)
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(DesignTokens.muted)
                TextField("Seconds", text: text)
                    .font(TypeScale.number(size: 28))
                    .monospacedDigit()
                    .foregroundStyle(DesignTokens.ink)
                    .keyboardType(.decimalPad)
                    .focused($focus, equals: field)
                    .frame(minHeight: Measure.hit)
                    .onChange(of: text.wrappedValue) { _, newValue in
                        apply(newValue, to: field)
                    }
                if !text.wrappedValue.isEmpty && Self.seconds(from: text.wrappedValue) == nil {
                    Text("Enter a number above zero.")
                        .font(TypeScale.body)
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var contact: some View {
        Group {
            if let url = URL(string: SettingsSurface.contactURL) {
                Link(destination: url) {
                    Label("Contact", systemImage: "arrow.up.right")
                        .font(TypeScale.body)
                        .foregroundStyle(DesignTokens.ink)
                        .frame(maxWidth: .infinity, minHeight: Measure.hit)
                        .background(DesignTokens.surface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                        .lifted()
                }
            }
        }
    }

    private func advance() {
        switch focus {
        case .reflect: focus = .breathe
        case .breathe: focus = .ambient
        default: focus = nil
        }
    }

    private func apply(_ raw: String, to field: Field) {
        let clean = Self.sanitize(raw)
        if clean != raw {
            assign(clean, to: field)
            return
        }
        guard let seconds = Self.seconds(from: clean) else { return }
        switch field {
        case .reflect:
            session.updateDurations(reflect: seconds, breathe: session.record.breatheSeconds, ambient: session.record.ambientSeconds)
        case .breathe:
            session.updateDurations(reflect: session.record.reflectSeconds, breathe: seconds, ambient: session.record.ambientSeconds)
        case .ambient:
            session.updateDurations(reflect: session.record.reflectSeconds, breathe: session.record.breatheSeconds, ambient: seconds)
        }
    }

    private func assign(_ clean: String, to field: Field) {
        switch field {
        case .reflect: reflectText = clean
        case .breathe: breatheText = clean
        case .ambient: ambientText = clean
        }
    }

    private func erase() async {
        resetting = true
        await session.resetAllData()
        resetting = false
        onDidReset()
    }

    private static func display(_ value: TimeInterval) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }

    private static func sanitize(_ raw: String) -> String {
        let separator = Locale.current.decimalSeparator ?? "."
        var result = ""
        var seenSeparator = false
        for character in raw {
            if character.isNumber {
                result.append(character)
            } else if String(character) == separator, !seenSeparator {
                result.append(character)
                seenSeparator = true
            }
        }
        return result
    }

    private static func seconds(from raw: String) -> TimeInterval? {
        let separator = Locale.current.decimalSeparator ?? "."
        let normalized = raw.replacingOccurrences(of: separator, with: ".")
        guard let value = Double(normalized), value.isFinite, value > 0, value < 24 * 60 * 60 else {
            return nil
        }
        return value
    }
}
