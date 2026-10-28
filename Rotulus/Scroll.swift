import Foundation

/// Scroll is tonight's makimono: a fold over three Panels.
/// The fold is Bare, Marked, or Rolled. `apply` is the only way it changes.
/// Set writes a LineMark. Waft writes a WaftMark with no text.
/// Furl moves focus only from a marked panel. Roll writes a NightMark.

struct Scroll: Codable, Equatable, Sendable {
    enum Phase: String, Codable, Equatable, Sendable {
        case bare
        case marked
        case rolled
    }

    enum Fold: Equatable, Sendable {
        case bare
        case marked
        case rolled(NightMark)
    }

    var dayKey: Int
    var panels: [Panel]
    var focus: PanelKind
    var fold: Fold

    var phase: Phase {
        switch fold {
        case .bare: .bare
        case .marked: .marked
        case .rolled: .rolled
        }
    }

    var isUntouched: Bool {
        if case .rolled = fold { return false }
        return panels.allSatisfy(\.isBare)
    }

    var focused: Panel? {
        panels.first { $0.kind == focus }
    }

    var allMarked: Bool {
        panels.count == PanelKind.allCases.count && panels.allSatisfy { $0.mark != nil }
    }

    static func tonight(dayKey: Int) -> Scroll {
        Scroll(
            dayKey: dayKey,
            panels: PanelKind.allCases.map { Panel(kind: $0, mark: nil) },
            focus: .reflect,
            fold: .bare
        )
    }

    func apply(_ verb: ScrollVerb) -> Result<Scroll, ScrollRefusal> {
        switch verb {
        case .set(let set):
            return applySet(set)
        case .waft:
            return applyWaft()
        case .furl(let furl):
            return applyFurl(furl)
        case .roll(let roll):
            return applyRoll(roll)
        }
    }

    private func applySet(_ set: Set) -> Result<Scroll, ScrollRefusal> {
        if case .rolled = fold { return .failure(.afterRoll) }
        let text = set.trimmed
        if text.isEmpty { return .failure(.emptyLine) }
        guard let index = panels.firstIndex(where: { $0.kind == focus }) else {
            return .failure(.emptyLine)
        }
        if panels[index].mark != nil { return .failure(.setOnMarked) }
        var next = self
        next.panels[index].mark = .line(LineMark(text: text))
        next.fold = .marked
        return .success(next)
    }

    private func applyWaft() -> Result<Scroll, ScrollRefusal> {
        if case .rolled = fold { return .failure(.afterRoll) }
        guard let index = panels.firstIndex(where: { $0.kind == focus }) else {
            return .failure(.furlOnBare)
        }
        if panels[index].mark != nil { return .failure(.setOnMarked) }
        var next = self
        next.panels[index].mark = .waft(WaftMark())
        next.fold = .marked
        return .success(next)
    }

    private func applyFurl(_ furl: Furl) -> Result<Scroll, ScrollRefusal> {
        _ = furl
        if case .rolled = fold { return .failure(.afterRoll) }
        guard let panel = focused else { return .failure(.furlOnBare) }
        if panel.isBare { return .failure(.furlOnBare) }
        guard let upcoming = focus.next else { return .failure(.noFurtherPanel) }
        var next = self
        next.focus = upcoming
        return .success(next)
    }

    private func applyRoll(_ roll: RollMark) -> Result<Scroll, ScrollRefusal> {
        if case .rolled = fold { return .failure(.rollOnRolled) }
        if !allMarked { return .failure(.rollIncomplete) }
        var next = self
        next.fold = .rolled(NightMark(scroll: self, sealedAt: roll.sealedAt))
        return .success(next)
    }

    enum CodingKeys: String, CodingKey {
        case dayKey
        case panels
        case focus
        case phase
        case night
    }

    init(dayKey: Int, panels: [Panel], focus: PanelKind, fold: Fold) {
        self.dayKey = dayKey
        self.panels = panels
        self.focus = focus
        self.fold = fold
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dayKey = try container.decode(Int.self, forKey: .dayKey)
        let panels = try container.decode([Panel].self, forKey: .panels)
        let focus = try container.decode(PanelKind.self, forKey: .focus)
        let phase = try container.decode(Phase.self, forKey: .phase)
        guard panels.map(\.kind) == PanelKind.allCases else {
            throw DecodingError.dataCorruptedError(
                forKey: .panels,
                in: container,
                debugDescription: "Panels must stay in canonical order."
            )
        }
        let fold: Fold
        switch phase {
        case .bare:
            guard panels.allSatisfy(\.isBare) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .phase,
                    in: container,
                    debugDescription: "A bare scroll cannot hold marks."
                )
            }
            fold = .bare
        case .marked:
            guard panels.contains(where: { $0.mark != nil }) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .phase,
                    in: container,
                    debugDescription: "A marked scroll needs a mark."
                )
            }
            fold = .marked
        case .rolled:
            let night = try container.decode(NightMark.self, forKey: .night)
            fold = .rolled(night)
        }
        self.init(dayKey: dayKey, panels: panels, focus: focus, fold: fold)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(dayKey, forKey: .dayKey)
        try container.encode(panels, forKey: .panels)
        try container.encode(focus, forKey: .focus)
        try container.encode(phase, forKey: .phase)
        if case .rolled(let night) = fold {
            try container.encode(night, forKey: .night)
        }
    }
}

enum ScrollVerb: Equatable, Sendable {
    case set(Set)
    case waft
    case furl(Furl)
    case roll(RollMark)
}

enum ScrollRefusal: String, Equatable, Error, Sendable {
    case furlOnBare
    case setOnMarked
    case rollIncomplete
    case rollOnRolled
    case afterRoll
    case emptyLine
    case noFurtherPanel

    var statusLine: String {
        switch self {
        case .furlOnBare:
            "Panel bare. Set or Waft first."
        case .setOnMarked:
            "Panel marked. Furl to the next chamber."
        case .rollIncomplete:
            "Scroll open. Mark every chamber, then roll."
        case .rollOnRolled:
            "Night sealed. This scroll stays rolled."
        case .afterRoll:
            "Night sealed. Set and Waft are closed."
        case .emptyLine:
            "Line empty. Write one release line."
        case .noFurtherPanel:
            "Scroll open. Roll when you are ready."
        }
    }
}
