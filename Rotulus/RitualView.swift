import SwiftUI

/// Tonight's rite. The screen sends Commit, Skip, Advance, and Seal to the session.
/// It does not touch the archive. Wide width unrolls with ViewThatFits and AnyLayout.

struct RitualView: View {
    var session: RitualSession
    var now: Date
    var breathCue: Bool = false
    var onHistory: () -> Void
    var onSettings: () -> Void
    var onReflect: () -> Void
    var onRetry: () -> Void

    @State private var line = ""
    @State private var committing = false
    @State private var sealPulse = 0
    @State private var breathing = false
    @State private var breathStarted = Date()
    @GestureState private var drag: CGFloat = 0
    @FocusState private var lineFocused: Bool
    @ScaledMetric(relativeTo: .largeTitle) private var displaySize: CGFloat = 52
    @ScaledMetric(relativeTo: .largeTitle) private var countSize: CGFloat = 64
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var surface: RitualSurface {
        RitualSurface.make(record: session.record, notice: session.notice, refusal: session.refusal, now: now)
    }

    private var scroll: Scroll {
        session.record.aligned(to: now).scroll
    }

    var body: some View {
        Group {
            switch surface.load {
            case .failed(let message):
                failed(message)
            case .empty:
                empty
            case .populated:
                populated
            }
        }
        .background(DesignTokens.bg)
        .navigationTitle("Tonight")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: Spacing.s4) {
                    iconButton("book.closed", label: "History", action: onHistory)
                    iconButton("gearshape", label: "Settings", action: onSettings)
                }
            }
        }
        .sensoryFeedback(.success, trigger: session.lastNight?.dayKey) { _, new in
            session.record.hapticsEnabled && new != nil
        }
        .onChange(of: session.lastNight?.dayKey) { _, new in
            if new != nil { sealPulse += 1 }
        }
        .onAppear {
            if breathCue { beginBreath() }
        }
        .onChange(of: breathCue) { _, on in
            if on { beginBreath() }
        }
        .onChange(of: breathOpen) { _, open in
            if !open { breathing = false }
        }
    }

    private var populated: some View {
        ScrollView {
            Group {
                if breathing {
                    TimelineView(.periodic(from: breathStarted, by: 1)) { context in
                        column(at: context.date)
                    }
                } else {
                    column(at: now)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func column(at date: Date) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s24) {
            header(at: date)
            stats
            makimono(at: date)
            if scroll.phase != .rolled {
                roller
            }
            recent
        }
        .padding(Spacing.s24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Wide width unrolls Reflect, Breathe, Ambient. Narrow width stacks them.
    private func makimono(at date: Date) -> some View {
        let row = panelRow(at: date)
        return Group {
            if scroll.phase == .rolled, !reduceMotion {
                PhaseAnimator([CGFloat(0.96), CGFloat(1)], trigger: sealPulse) { phase in
                    row.scaleEffect(phase, anchor: .leading)
                } animation: { _ in
                    Motion.press
                }
            } else {
                row
            }
        }
    }

    private func panelRow(at date: Date) -> some View {
        ViewThatFits(in: .horizontal) {
            AnyLayout(HStackLayout(alignment: .top, spacing: Spacing.s24)) {
                chamber(.reflect, at: date)
                chamber(.breathe, at: date)
                chamber(.ambient, at: date)
            }
            .frame(minWidth: unrollWidth, maxWidth: .infinity, alignment: .leading)
            AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.s24)) {
                chamber(.reflect, at: date)
                chamber(.breathe, at: date)
                chamber(.ambient, at: date)
            }
        }
    }

    private var unrollWidth: CGFloat {
        Measure.art * 3 + Spacing.s24 * 2
    }

    @ViewBuilder
    private func chamber(_ kind: PanelKind, at date: Date) -> some View {
        let panel = scroll.panels.first { $0.kind == kind }
        let bare = panel?.isBare ?? true
        let focused = scroll.focus == kind && scroll.phase != .rolled
        let line = shownLine(panel)
        if kind == .ambient {
            ambientChamber(line: line, bare: bare, focused: focused)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if scroll.phase == .rolled || !focused {
            quietChamber(kind, line: line, bare: bare, opensReflect: kind == .reflect && !bare && scroll.phase != .rolled)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            focusedChamber(kind, line: line, bare: bare, at: date)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func focusedChamber(_ kind: PanelKind, line: String, bare: Bool, at date: Date) -> some View {
        let settling = kind == .breathe && breathing
        let caption: String = {
            if settling {
                let elapsed = max(0, date.timeIntervalSince(breathStarted))
                let cue = Cue.at(min(elapsed, session.record.breatheSeconds))
                return "\(kind.displayName). \(cueWord(cue))."
            }
            return "\(kind.displayName). \(bare ? "Bare" : "Marked")."
        }()
        return VStack(alignment: .leading, spacing: Spacing.s12) {
            StatusCaption(text: caption)
            Text(bare ? kind.displayName : line)
                .font(TypeScale.display(size: displaySize))
                .tracking(-0.5)
                .foregroundStyle(DesignTokens.ink)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            if bare {
                if settling {
                    breathSettle(at: date)
                } else if kind == .breathe {
                    breatheBare
                } else {
                    composer
                }
            }
        }
    }

    private func quietChamber(_ kind: PanelKind, line: String, bare: Bool, opensReflect: Bool) -> some View {
        let body = VStack(alignment: .leading, spacing: Spacing.s8) {
            StatusCaption(text: "\(kind.displayName). \(bare ? "Bare" : "Marked").")
            Text(line)
                .font(TypeScale.body)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.s16)
        .frame(maxWidth: .infinity, minHeight: Measure.hit, alignment: .leading)
        .background(DesignTokens.surface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .lifted()

        return Group {
            if opensReflect {
                Button(action: onReflect) { body }
                    .buttonStyle(PressCardStyle())
                    .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            } else {
                body
            }
        }
    }

    private func ambientChamber(line: String, bare: Bool, focused: Bool) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            ZStack(alignment: .bottomLeading) {
                AmbientDither(moving: scroll.phase != .rolled)
                Plate(chip: true) {
                    VStack(alignment: .leading, spacing: Spacing.s8) {
                        StatusCaption(text: "Ambient. \(bare ? "Bare" : "Marked").")
                        Text(bare ? "Still open" : line)
                            .font(TypeScale.body)
                            .foregroundStyle(DesignTokens.ink)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(Spacing.s12)
            }
            .frame(height: Measure.dither)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .lifted()
            if focused, bare {
                composer
            } else if focused {
                Text(line)
                    .font(TypeScale.display(size: displaySize))
                    .tracking(-0.5)
                    .foregroundStyle(DesignTokens.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    /// Bare Breathe: one job (write the release line), one filled next tap (Commit line).
    /// Start breath and Skip stay as quiet exits, sequenced under the primary.
    private var breatheBare: some View {
        VStack(alignment: .leading, spacing: Spacing.s16) {
            Text("Write one release line for tonight.")
                .font(TypeScale.body)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            releaseField
            Button("Commit line", action: commitLine)
                .buttonStyle(SoftCardButtonStyle(accent: true))
                .disabled(!surface.canSet || committing)
            VStack(alignment: .leading, spacing: Spacing.s8) {
                Button("Start breath", action: beginBreath)
                    .buttonStyle(QuietTextButtonStyle())
                    .disabled(!breathOpen)
                Button("Skip this chamber", action: skip)
                    .buttonStyle(QuietTextButtonStyle())
                    .disabled(!surface.canWaft)
            }
            .padding(.top, Spacing.s4)
        }
    }

    /// Settle: stay with the count. No Release/Commit on the canvas while the
    /// timer runs. Skip is a quiet escape, never the filled primary.
    private func breathSettle(at date: Date) -> some View {
        let left = remaining(at: date)
        return VStack(alignment: .leading, spacing: Spacing.s16) {
            if left > 0 {
                Text("Stay with the count.")
                    .font(TypeScale.callout)
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(left, format: .number.precision(.fractionLength(0)))
                    .font(TypeScale.number(size: countSize))
                    .monospacedDigit()
                    .foregroundStyle(DesignTokens.accent)
                    .contentTransition(.numericText(value: left))
                    .animation(Motion.state, value: Int(left))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel("Seconds left")
                Button("Skip this chamber", action: skip)
                    .buttonStyle(QuietTextButtonStyle())
                    .disabled(!surface.canWaft)
            } else {
                Text("Count finished. Commit the release line.")
                    .font(TypeScale.body)
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
                releaseField
                Button("Commit line", action: commitLine)
                    .buttonStyle(SoftCardButtonStyle(accent: true))
                    .disabled(!surface.canSet || committing)
                Button("Skip this chamber", action: skip)
                    .buttonStyle(QuietTextButtonStyle())
                    .disabled(!surface.canWaft)
            }
        }
    }

    private var releaseField: some View {
        TextField("Release line", text: $line)
            .font(TypeScale.body)
            .foregroundStyle(DesignTokens.ink)
            .textFieldStyle(.plain)
            .focused($lineFocused)
            .submitLabel(.done)
            .frame(minHeight: Measure.hit)
            .padding(.horizontal, Spacing.s16)
            .background(DesignTokens.surface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .lifted()
            .onSubmit(commitLine)
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            releaseField
            Button("Commit line", action: commitLine)
                .buttonStyle(SoftCardButtonStyle(accent: live == .commit))
                .disabled(!surface.canSet || committing)
            Button("Skip", action: skip)
                .buttonStyle(SoftCardButtonStyle(accent: false))
                .disabled(!surface.canWaft)
        }
    }

    private var roller: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            if drag < -Spacing.s8, let next = scroll.focus.next {
                Text(next.displayName)
                    .font(TypeScale.callout)
                    .foregroundStyle(DesignTokens.ink)
                    .opacity(reduceMotion ? 1 : min(1, Double(-drag / Spacing.s48)))
                    .offset(y: reduceMotion ? 0 : drag / 4)
            }
            Button("Advance", action: { session.furl(now: now) })
                .buttonStyle(SoftCardButtonStyle(accent: live == .advance))
                .disabled(!surface.canFurl)
            if surface.canRoll {
                Button("Seal night", action: seal)
                    .buttonStyle(SoftCardButtonStyle(accent: live == .seal))
                    .disabled(committing || !surface.canRoll)
            }
        }
        .gesture(unfurl)
    }

    private func header(at date: Date) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s12) {
                if let day = DayKey.date(from: scroll.dayKey, calendar: .current) {
                    Text(day, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                        .font(TypeScale.body)
                        .foregroundStyle(DesignTokens.ink)
                        .lineLimit(1)
                        .truncationMode(.tail)
                } else {
                    Text("unknown")
                        .font(TypeScale.body)
                        .foregroundStyle(DesignTokens.ink)
                }
                if breathing {
                    metric(remaining(at: date), size: countSize, label: "Seconds left")
                } else {
                    metric(Double(surface.streak), size: 28, label: "Streak")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            StatusCaption(text: headerStatus(at: date))
        }
    }

    private func metric(_ value: Double, size: CGFloat, label: String) -> some View {
        let shown = Double(Int(value))
        return Text(shown, format: .number.precision(.fractionLength(0)))
            .font(TypeScale.number(size: size))
            .monospacedDigit()
            .foregroundStyle(DesignTokens.accent)
            .contentTransition(.numericText(value: shown))
            .animation(Motion.state, value: Int(value))
            .lineLimit(1)
            .layoutPriority(1)
            .accessibilityLabel(label)
    }

    private func headerStatus(at date: Date) -> String {
        if let refusal = surface.refusal { return refusal }
        if breathing {
            let elapsed = max(0, date.timeIntervalSince(breathStarted))
            let cue = Cue.at(min(elapsed, session.record.breatheSeconds))
            return "Breathe. \(cueWord(cue))."
        }
        return surface.status
    }

    private var stats: some View {
        Plate(chip: true) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s24) {
                stat("Nights", value: session.record.highestChapter)
                stat("Best", value: session.record.bestScore())
            }
        }
    }

    private func stat(_ title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text(title)
                .font(TypeScale.chip)
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(DesignTokens.muted)
                .lineLimit(1)
            Text(value, format: .number.precision(.fractionLength(0)))
                .font(TypeScale.number(size: 22))
                .monospacedDigit()
                .foregroundStyle(DesignTokens.ink)
                .contentTransition(.numericText(value: Double(value)))
                .animation(Motion.state, value: value)
                .lineLimit(1)
                .layoutPriority(1)
        }
        .frame(minHeight: Measure.hit, alignment: .leading)
    }

    @ViewBuilder
    private var recent: some View {
        let nights = Array(HistorySurface.make(record: session.record, notice: nil).nights.prefix(2))
        if let latest = nights.first {
            VStack(alignment: .leading, spacing: Spacing.s12) {
                StatusCaption(text: "Last seal")
                Button(action: onHistory) {
                    VStack(alignment: .leading, spacing: Spacing.s8) {
                        if let date = DayKey.date(from: latest.dayKey, calendar: .current) {
                            Text(date, format: .dateTime.month(.abbreviated).day())
                                .font(TypeScale.caption)
                                .foregroundStyle(DesignTokens.muted)
                                .lineLimit(1)
                        }
                        Text(latest.reflect ?? latest.breathe ?? latest.ambient ?? "Skipped")
                            .font(TypeScale.body)
                            .foregroundStyle(DesignTokens.ink)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(Spacing.s16)
                    .frame(maxWidth: .infinity, minHeight: Measure.hit, alignment: .leading)
                    .background(DesignTokens.surface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                    .lifted()
                    .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                }
                .buttonStyle(PressCardStyle())
            }
        }
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
                Text("Tonight is open.")
                    .font(TypeScale.display(size: displaySize))
                    .tracking(-0.5)
                    .foregroundStyle(DesignTokens.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Write the first line.")
                    .font(TypeScale.body)
                    .foregroundStyle(DesignTokens.ink)
                if let refusal = surface.refusal {
                    Text(refusal)
                        .font(TypeScale.body)
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                composer
            }
            .padding(Spacing.s24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .containerRelativeFrame(.vertical, alignment: .top)
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
            }
            .padding(Spacing.s24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var unfurl: some Gesture {
        DragGesture(minimumDistance: Spacing.s12)
            .updating($drag) { value, state, _ in
                state = value.translation.height
            }
            .onEnded { value in
                let travel = min(value.translation.height, value.predictedEndTranslation.height)
                if travel < -Spacing.s48 {
                    session.furl(now: now)
                }
            }
    }

    private func iconButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .foregroundStyle(DesignTokens.ink)
                .frame(minWidth: Measure.hit, minHeight: Measure.hit)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressCardStyle())
        .accessibilityLabel(label)
    }

    private func commitLine() {
        guard !committing else { return }
        committing = true
        session.setLine(line, now: now)
        committing = false
        if session.refusal == nil {
            line = ""
            lineFocused = false
        }
    }

    private func skip() {
        guard !committing else { return }
        committing = true
        session.waft(now: now)
        committing = false
    }

    private func seal() {
        guard !committing else { return }
        committing = true
        session.roll(now: now)
        committing = false
    }

    private func beginBreath() {
        guard breathOpen, !breathing else { return }
        breathStarted = Date()
        breathing = true
    }

    private var breathOpen: Bool {
        scroll.focus == .breathe && scroll.phase != .rolled && scroll.focused?.isBare == true
    }

    private func remaining(at date: Date) -> Double {
        let elapsed = max(0, date.timeIntervalSince(breathStarted))
        return max(0, session.record.breatheSeconds - elapsed)
    }

    private func cueWord(_ cue: Cue) -> String {
        switch cue {
        case .settle: "Settle"
        case .draw: "Draw"
        case .release: "Release"
        case .rest: "Rest"
        }
    }

    private func shownLine(_ panel: Panel?) -> String {
        if let text = panel?.mark?.lineText, !text.isEmpty { return text }
        if panel?.mark != nil { return "Skipped" }
        return "Still open"
    }

    private var live: LiveVerb {
        if surface.canRoll { return .seal }
        if surface.canSet { return .commit }
        if surface.canFurl { return .advance }
        return .commit
    }

    private enum LiveVerb {
        case commit
        case advance
        case seal
    }
}

struct RitualSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s20) {
            RoundedRectangle(cornerRadius: Radius.chip).frame(width: Measure.side, height: Spacing.s24)
            RoundedRectangle(cornerRadius: Radius.card).frame(height: Measure.hit)
            RoundedRectangle(cornerRadius: Radius.card).frame(height: Measure.dither)
        }
        .padding(Spacing.s24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(DesignTokens.surface)
        .background(DesignTokens.bg)
    }
}
