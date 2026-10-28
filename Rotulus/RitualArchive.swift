import Foundation

/// RitualArchive is the only storage seam. The file in Application Support is a
/// projection of the in-memory record. The same payload is mirrored under
/// `rtl.record.v1`. Writes are atomic. A corrupt file falls back to `.backup`.

actor RitualArchive {
    struct Loaded: Equatable, Sendable {
        var record: RitualRecord
        var notice: String?
    }

    private let directory: URL
    private let defaults: UserDefaults
    private let seedDemo: Bool
    private let fileManager: FileManager
    private var acceptedGeneration = 0

    private var fileURL: URL { directory.appendingPathComponent("ritual.json") }
    private var backupURL: URL { directory.appendingPathComponent("ritual.json.backup") }

    init(directory: URL, defaults: UserDefaults, seedDemo: Bool, fileManager: FileManager = .default) {
        self.directory = directory
        self.defaults = defaults
        self.seedDemo = seedDemo
        self.fileManager = fileManager
    }

    init(directory: URL, suiteName: String, seedDemo: Bool) {
        let defaults = UserDefaults(suiteName: suiteName) ?? UserDefaults()
        self.init(directory: directory, defaults: defaults, seedDemo: seedDemo)
    }

    func hasMirroredPayload() -> Bool {
        guard let data = defaults.data(forKey: RitualRecord.storageKey) else { return false }
        return data.isEmpty == false
    }

    func load(now: Date = Date()) -> Loaded {
        if Task.isCancelled {
            return Loaded(record: .empty(now: now), notice: nil)
        }
        let loaded = read(now: now)
        guard seedDemo, defaults.bool(forKey: RitualRecord.demoKey) == false else {
            return loaded
        }
        defaults.set(true, forKey: RitualRecord.demoKey)
        if loaded.notice == nil && loaded.record.nights.isEmpty && loaded.record.scroll.isUntouched && loaded.record.onboardingComplete == false {
            let seeded = Self.demoRecord(now: now)
            do {
                try write(seeded)
            } catch {
                return Loaded(
                    record: seeded,
                    notice: "Demo night stayed in memory. The save did not land."
                )
            }
            return Loaded(record: seeded, notice: nil)
        }
        return loaded
    }

    func save(_ record: RitualRecord, generation: Int) throws {
        try Task.checkCancellation()
        guard generation >= acceptedGeneration else { return }
        acceptedGeneration = generation
        try write(record)
    }

    func reset(now: Date = Date()) throws -> RitualRecord {
        try Task.checkCancellation()
        acceptedGeneration += 1
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
        if fileManager.fileExists(atPath: backupURL.path) {
            try fileManager.removeItem(at: backupURL)
        }
        defaults.removeObject(forKey: RitualRecord.storageKey)
        return .empty(now: now)
    }

    func nextGeneration() -> Int {
        acceptedGeneration += 1
        return acceptedGeneration
    }

    private func read(now: Date) -> Loaded {
        switch contents(of: fileURL) {
        case .missing:
            if let mirrored = defaults.data(forKey: RitualRecord.storageKey), let record = decode(mirrored) {
                return Loaded(record: record, notice: nil)
            }
            return Loaded(record: .empty(now: now), notice: nil)
        case .data(let data):
            if let record = decode(data) {
                return Loaded(record: record, notice: nil)
            }
            if case .data(let backup) = contents(of: backupURL), let record = decode(backup) {
                return Loaded(
                    record: record,
                    notice: "Saved scroll was unreadable. Restored the previous copy."
                )
            }
            return Loaded(
                record: .empty(now: now),
                notice: "Saved scroll was unreadable. Started from an empty night."
            )
        case .unreadable:
            return Loaded(
                record: .empty(now: now),
                notice: "Saved scroll was unreadable. Started from an empty night."
            )
        }
    }

    private enum Read {
        case missing
        case data(Data)
        case unreadable
    }

    private func contents(of url: URL) -> Read {
        do {
            return .data(try Data(contentsOf: url))
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return .missing
        } catch {
            return .unreadable
        }
    }

    private func write(_ record: RitualRecord) throws {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try Self.makeEncoder().encode(record)
        try data.write(to: fileURL, options: .atomic)
        if fileManager.fileExists(atPath: backupURL.path) {
            try fileManager.removeItem(at: backupURL)
        }
        try fileManager.copyItem(at: fileURL, to: backupURL)
        defaults.set(data, forKey: RitualRecord.storageKey)
    }

    private func decode(_ data: Data) -> RitualRecord? {
        do {
            return try Self.makeDecoder().decode(RitualRecord.self, from: data)
        } catch {
            return nil
        }
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static func demoRecord(now: Date, calendar: Calendar = .current) -> RitualRecord {
        let today = DayKey.int(for: now, calendar: calendar)
        var record = RitualRecord.empty(now: now, calendar: calendar)
        record.onboardingComplete = true
        let priorLines = [
            ("Left the list.", "Four slow breaths.", "Window cracked."),
            ("Work stays there.", "Counted to four.", "Lamp dim."),
            ("No more replies.", "Shoulders down.", "Hall quiet."),
            ("The kitchen is done.", "Longer exhale.", "Street hush."),
            ("Said the thing.", "Unclenched the jaw.", "One light left."),
            ("Closed the notebook.", "Breath even.", "Room cool.")
        ]
        for offset in 1...6 {
            guard let key = DayKey.adding(days: -offset, to: today, calendar: calendar),
                  let date = DayKey.date(from: key, calendar: calendar) else { continue }
            let lines = priorLines[offset - 1]
            record.nights.append(
                NightMark(
                    dayKey: key,
                    reflect: lines.0,
                    breathe: lines.1,
                    ambient: lines.2,
                    sealedAt: date
                )
            )
        }
        let opened = record.applying(.set(Set(line: "The room can wait.")), now: now, calendar: calendar)
        if case .success(let marked) = opened {
            let furled = marked.applying(.furl(Furl()), now: now, calendar: calendar)
            if case .success(let ready) = furled {
                record = ready
            }
        }
        return record
    }
}
