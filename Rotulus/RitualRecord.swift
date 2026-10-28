import Foundation

/// RitualRecord is the single persisted root (`rtl.record.v1`).
/// It holds tonight's Scroll, sealed NightMarks, untouched Blanks,
/// chamber durations, haptics, and the onboarding flag.
/// Streak and counts are derived from NightMarks. Blank is not a seal and not a gap.

struct RitualRecord: Equatable, Sendable {
    static let currentSchema = 1
    static let storageKey = "rtl.record.v1"
    static let demoKey = "rtl.demo.v1"

    var schemaVersion: Int
    var scroll: Scroll
    var nights: [NightMark]
    var blanks: [Blank]
    var reflectSeconds: TimeInterval
    var breatheSeconds: TimeInterval
    var ambientSeconds: TimeInterval
    var hapticsEnabled: Bool
    var onboardingComplete: Bool

    static func empty(now: Date, calendar: Calendar = .current) -> RitualRecord {
        let key = DayKey.int(for: now, calendar: calendar)
        return RitualRecord(
            schemaVersion: currentSchema,
            scroll: Scroll.tonight(dayKey: key),
            nights: [],
            blanks: [],
            reflectSeconds: PanelKind.reflect.defaultSeconds,
            breatheSeconds: PanelKind.breathe.defaultSeconds,
            ambientSeconds: PanelKind.ambient.defaultSeconds,
            hapticsEnabled: true,
            onboardingComplete: false
        )
    }

    var highestChapter: Int { nights.count }

    func streak(asOf date: Date, calendar: Calendar = .current) -> Int {
        let sealed = Swift.Set(nights.map(\.dayKey))
        let skipped = Swift.Set(blanks.map(\.dayKey))
        var cursor = DayKey.int(for: date, calendar: calendar)
        if !sealed.contains(cursor) {
            guard let previous = DayKey.adding(days: -1, to: cursor, calendar: calendar) else {
                return 0
            }
            cursor = previous
        }
        var count = 0
        var steps = 0
        while steps < 3660 {
            steps += 1
            if sealed.contains(cursor) {
                count += 1
            } else if skipped.contains(cursor) {
                // Untouched night: neither a completed rite nor a broken streak.
            } else {
                break
            }
            guard let previous = DayKey.adding(days: -1, to: cursor, calendar: calendar) else {
                break
            }
            cursor = previous
        }
        return count
    }

    /// Best sealed run is derived by walking every NightMark and Blank. Not stored.
    func bestScore(calendar: Calendar = .current) -> Int {
        let keys = nights.map(\.dayKey)
        guard let latest = keys.max(), let date = DayKey.date(from: latest, calendar: calendar) else {
            return 0
        }
        return streak(asOf: date, calendar: calendar)
    }

    func applying(_ verb: ScrollVerb, now: Date, calendar: Calendar = .current) -> Result<RitualRecord, ScrollRefusal> {
        var next = aligned(to: now, calendar: calendar)
        let result = next.scroll.apply(verb)
        switch result {
        case .failure(let refusal):
            return .failure(refusal)
        case .success(let scroll):
            next.scroll = scroll
            if case .rolled(let night) = scroll.fold {
                if !next.nights.contains(where: { $0.dayKey == night.dayKey }) {
                    next.nights.append(night)
                }
            }
            return .success(next)
        }
    }

    func aligned(to date: Date, calendar: Calendar = .current) -> RitualRecord {
        let key = DayKey.int(for: date, calendar: calendar)
        guard scroll.dayKey != key else { return self }
        var next = self
        if let blank = Blank.written(dayKey: scroll.dayKey, scroll: scroll),
           !next.blanks.contains(where: { $0.dayKey == blank.dayKey }),
           !next.nights.contains(where: { $0.dayKey == blank.dayKey }) {
            next.blanks.append(blank)
        }
        if case .rolled = scroll.fold {
            next.scroll = Scroll.tonight(dayKey: key)
        } else if scroll.isUntouched {
            next.scroll = Scroll.tonight(dayKey: key)
        } else if case .marked = scroll.fold, scroll.dayKey != key {
            next.scroll = Scroll.tonight(dayKey: key)
        }
        return next
    }
}

extension RitualRecord: Codable {
    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case scroll
        case nights
        case blanks
        case reflectSeconds
        case breatheSeconds
        case ambientSeconds
        case hapticsEnabled
        case onboardingComplete
        case bestScore
        case highestChapter
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(Int.self, forKey: .schemaVersion)
        guard version == Self.currentSchema else {
            throw DecodingError.dataCorruptedError(
                forKey: .schemaVersion,
                in: container,
                debugDescription: "Unknown ritual schema."
            )
        }
        schemaVersion = version
        scroll = try container.decode(Scroll.self, forKey: .scroll)
        nights = try container.decode([NightMark].self, forKey: .nights)
        blanks = try container.decode([Blank].self, forKey: .blanks)
        reflectSeconds = try container.decode(TimeInterval.self, forKey: .reflectSeconds)
        breatheSeconds = try container.decode(TimeInterval.self, forKey: .breatheSeconds)
        ambientSeconds = try container.decode(TimeInterval.self, forKey: .ambientSeconds)
        hapticsEnabled = try container.decode(Bool.self, forKey: .hapticsEnabled)
        onboardingComplete = try container.decode(Bool.self, forKey: .onboardingComplete)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(scroll, forKey: .scroll)
        try container.encode(nights, forKey: .nights)
        try container.encode(blanks, forKey: .blanks)
        try container.encode(reflectSeconds, forKey: .reflectSeconds)
        try container.encode(breatheSeconds, forKey: .breatheSeconds)
        try container.encode(ambientSeconds, forKey: .ambientSeconds)
        try container.encode(hapticsEnabled, forKey: .hapticsEnabled)
        try container.encode(onboardingComplete, forKey: .onboardingComplete)
        try container.encode(bestScore(), forKey: .bestScore)
        try container.encode(highestChapter, forKey: .highestChapter)
    }
}
