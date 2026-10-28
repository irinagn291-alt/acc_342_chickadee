import Foundation

/// Read models between RitualRecord and the screens. The views in a later
/// layer render these. They do not decide whether Set, Furl, or Roll may run.

enum SurfaceLoad: Equatable, Sendable {
    case empty
    case populated
    case failed(String)
}

struct RitualSurface: Equatable, Sendable {
    var focusName: String
    var markState: String
    var status: String
    var canSet: Bool
    var canWaft: Bool
    var canFurl: Bool
    var canRoll: Bool
    var streak: Int
    var refusal: String?
    var load: SurfaceLoad

    static func make(record: RitualRecord, notice: String?, refusal: ScrollRefusal?, now: Date = Date()) -> RitualSurface {
        let aligned = record.aligned(to: now)
        let focus = aligned.scroll.focus
        let marked = aligned.scroll.focused?.isBare == false
        let rolled = aligned.scroll.phase == .rolled
        let markState = rolled ? "Rolled" : (marked ? "Marked" : "Bare")
        let load: SurfaceLoad
        if let notice {
            load = .failed(notice)
        } else if aligned.scroll.isUntouched && aligned.nights.isEmpty {
            load = .empty
        } else {
            load = .populated
        }
        return RitualSurface(
            focusName: focus.displayName,
            markState: markState,
            status: "\(focus.displayName). \(markState).",
            canSet: !rolled && aligned.scroll.focused?.isBare == true,
            canWaft: !rolled && aligned.scroll.focused?.isBare == true,
            canFurl: !rolled && marked && focus.next != nil,
            canRoll: !rolled && aligned.scroll.allMarked,
            streak: aligned.streak(asOf: now),
            refusal: refusal?.statusLine,
            load: load
        )
    }
}

struct HistorySurface: Equatable, Sendable {
    static let emptyTitle = "Build tonight's rite. Skip a block if you must."
    static let beginTitle = "Begin"

    var nights: [NightMark]
    var load: SurfaceLoad

    static func make(record: RitualRecord, notice: String?) -> HistorySurface {
        let nights = record.nights.sorted { $0.dayKey > $1.dayKey }
        let load: SurfaceLoad
        if let notice {
            load = .failed(notice)
        } else if nights.isEmpty {
            load = .empty
        } else {
            load = .populated
        }
        return HistorySurface(nights: nights, load: load)
    }
}

struct SettingsSurface: Equatable, Sendable {
    static let contactURL = "https://rotulus-scroll.pro/contact-us"
    static let resetWarning = "Reset local data. Tonight's scroll and every sealed night on this device will be erased."

    var reflectSeconds: TimeInterval
    var breatheSeconds: TimeInterval
    var ambientSeconds: TimeInterval
    var hapticsEnabled: Bool
    var load: SurfaceLoad

    static func make(record: RitualRecord, notice: String?) -> SettingsSurface {
        let load: SurfaceLoad = notice.map { .failed($0) } ?? .populated
        return SettingsSurface(
            reflectSeconds: record.reflectSeconds,
            breatheSeconds: record.breatheSeconds,
            ambientSeconds: record.ambientSeconds,
            hapticsEnabled: record.hapticsEnabled,
            load: load
        )
    }
}

struct OnboardingSurface: Equatable, Sendable {
    static let steps: [String] = [
        "End the day on one scroll. Three chambers, in order.",
        "Commit one release line, or skip the chamber.",
        "Roll the night shut. It stays on this device."
    ]

    var stepIndex: Int
    var complete: Bool

    static func make(record: RitualRecord) -> OnboardingSurface {
        OnboardingSurface(stepIndex: 0, complete: record.onboardingComplete)
    }
}

extension PanelKind {
    var displayName: String {
        switch self {
        case .reflect: "Reflect"
        case .breathe: "Breathe"
        case .ambient: "Ambient"
        }
    }
}

/// Procedural wash only. This product ships no audio files.
enum AmbientWash {
    static let shipsAudioFiles = false
}
