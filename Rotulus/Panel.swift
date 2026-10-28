import Foundation

/// A Panel is one chamber of tonight's makimono. Reflect, Breathe, and Ambient
/// stay in that order. A panel is Bare until Set or Waft writes a mark.

enum PanelKind: String, Codable, CaseIterable, Equatable, Sendable {
    case reflect
    case breathe
    case ambient

    var defaultSeconds: TimeInterval {
        switch self {
        case .reflect: 90
        case .breathe: 120
        case .ambient: 90
        }
    }

    var next: PanelKind? {
        switch self {
        case .reflect: .breathe
        case .breathe: .ambient
        case .ambient: nil
        }
    }
}

enum PanelMark: Codable, Equatable, Sendable {
    case line(LineMark)
    case waft(WaftMark)

    var lineText: String? {
        if case .line(let mark) = self { return mark.text }
        return nil
    }
}

struct Panel: Codable, Equatable, Sendable {
    var kind: PanelKind
    var mark: PanelMark?

    var isBare: Bool { mark == nil }

    /// Breathe cues at fixed elapsed seconds inside the 120s chamber.
    /// `Cue.at` is the only lookup. The wash stays procedural.
    enum Cue: String, Codable, Equatable, Sendable {
        case settle
        case draw
        case release
        case rest

        static func at(_ elapsed: TimeInterval) -> Cue {
            if elapsed < 30 { return .settle }
            if elapsed < 60 { return .draw }
            if elapsed < 90 { return .release }
            return .rest
        }
    }
}

/// Call shape for the breathe chamber: Cue(at: elapsed) is `Cue.at`.
typealias Cue = Panel.Cue
