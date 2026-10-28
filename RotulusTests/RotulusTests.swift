import XCTest
@testable import Rotulus

/// Family invariant: Canonical order. Durations 90/120/90. Skip allowed.
/// Cue(at: elapsed). Procedural ambient, not shipped audio files.
/// Streak on completed nights.
final class RotulusTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        if let zone = TimeZone(secondsFromGMT: 0) {
            calendar.timeZone = zone
        }
        return calendar
    }

    private var now: Date { Date(timeIntervalSince1970: 1_761_480_000) }

    func testCanonicalOrderDurationsAndCue() {
        XCTAssertEqual(PanelKind.allCases, [.reflect, .breathe, .ambient])
        XCTAssertEqual(PanelKind.reflect.defaultSeconds, 90)
        XCTAssertEqual(PanelKind.breathe.defaultSeconds, 120)
        XCTAssertEqual(PanelKind.ambient.defaultSeconds, 90)
        let elapsed: TimeInterval = 0
        XCTAssertEqual(Cue.at(elapsed), .settle)
        XCTAssertEqual(Cue.at(30), .draw)
        XCTAssertEqual(Cue.at(60), .release)
        XCTAssertEqual(Cue.at(90), .rest)
        XCTAssertEqual(Cue.at(120), .rest)
        XCTAssertFalse(AmbientWash.shipsAudioFiles)
    }

    func testSetEmptyPopulatedAndMarked() {
        let scroll = Scroll.tonight(dayKey: DayKey.int(for: now, calendar: calendar))
        XCTAssertEqual(scroll.apply(.set(Set(line: "   "))).refusal, .emptyLine)
        XCTAssertEqual(scroll.apply(.set(Set(line: "\n"))).refusal, .emptyLine)
        let marked = scroll.apply(.set(Set(line: "  Leave it here.  "))).scroll
        XCTAssertEqual(marked?.phase, .marked)
        XCTAssertEqual(marked?.focused?.mark, .line(LineMark(text: "Leave it here.")))
        XCTAssertEqual(marked?.apply(.set(Set(line: "Again."))).refusal, .setOnMarked)
    }

    func testWaftWritesNoTextAndSetThenFurlThenRoll() {
        var scroll = Scroll.tonight(dayKey: DayKey.int(for: now, calendar: calendar))
        XCTAssertEqual(scroll.apply(.furl(Furl())).refusal, .furlOnBare)
        scroll = scroll.apply(.set(Set(line: "Day closed."))).scroll ?? scroll
        XCTAssertEqual(scroll.apply(.furl(Furl())).scroll?.focus, .breathe)
        scroll = scroll.apply(.furl(Furl())).scroll ?? scroll
        scroll = scroll.apply(.waft).scroll ?? scroll
        XCTAssertEqual(scroll.focused?.mark, .waft(WaftMark()))
        XCTAssertNil(scroll.focused?.mark?.lineText)
        XCTAssertEqual(scroll.apply(.roll(RollMark(sealedAt: now))).refusal, .rollIncomplete)
        scroll = scroll.apply(.furl(Furl())).scroll ?? scroll
        scroll = scroll.apply(.set(Set(line: "Lamp off."))).scroll ?? scroll
        let rolled = scroll.apply(.roll(RollMark(sealedAt: now))).scroll
        XCTAssertEqual(rolled?.phase, .rolled)
        guard case .rolled(let night) = rolled?.fold else {
            XCTFail("Roll writes NightMark")
            return
        }
        XCTAssertEqual(night.reflect, "Day closed.")
        XCTAssertNil(night.breathe)
        XCTAssertEqual(night.ambient, "Lamp off.")
        XCTAssertEqual(rolled?.apply(.roll(RollMark(sealedAt: now))).refusal, .rollOnRolled)
        XCTAssertEqual(rolled?.apply(.set(Set(line: "More."))).refusal, .afterRoll)
        XCTAssertEqual(rolled?.apply(.waft).refusal, .afterRoll)
    }

    func testFoldAdvancesOnlyThroughApply() {
        let bare = Scroll.tonight(dayKey: 20261025)
        XCTAssertEqual(bare.phase, .bare)
        XCTAssertEqual(Blank.written(dayKey: bare.dayKey, scroll: bare), Blank(dayKey: bare.dayKey))
        let marked = bare.apply(.set(Set(line: "One line."))).scroll
        XCTAssertEqual(marked?.phase, .marked)
        XCTAssertNil(Blank.written(dayKey: bare.dayKey, scroll: marked ?? bare))
        XCTAssertNotEqual(bare.phase, .rolled)
        let refused = bare.apply(.roll(RollMark(sealedAt: now)))
        XCTAssertEqual(refused.refusal, .rollIncomplete)
        XCTAssertEqual(refused.scroll?.phase, nil)
    }

    func testBlankIsNeitherGapNorSealedNight() throws {
        var record = RitualRecord.empty(now: now, calendar: calendar)
        let today = DayKey.int(for: now, calendar: calendar)
        let yesterday = try XCTUnwrap(DayKey.adding(days: -1, to: today, calendar: calendar))
        let twoAgo = try XCTUnwrap(DayKey.adding(days: -2, to: today, calendar: calendar))
        let threeAgo = try XCTUnwrap(DayKey.adding(days: -3, to: today, calendar: calendar))
        record.nights = [
            NightMark(dayKey: threeAgo, reflect: "A", breathe: "B", ambient: "C", sealedAt: now),
            NightMark(dayKey: yesterday, reflect: "A", breathe: "B", ambient: "C", sealedAt: now)
        ]
        record.blanks = [Blank(dayKey: twoAgo)]
        XCTAssertEqual(record.streak(asOf: now, calendar: calendar), 2)
        XCTAssertEqual(record.highestChapter, 2)
        record.blanks = []
        XCTAssertEqual(record.streak(asOf: now, calendar: calendar), 1)
    }

    func testPersistenceRoundTripAndBackup() async throws {
        let suite = "rotulus.tests.\(UUID().uuidString)"
        if let scrub = UserDefaults(suiteName: suite) {
            scrub.removePersistentDomain(forName: suite)
        }
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("rotulus-\(UUID().uuidString)", isDirectory: true)
        let archive = RitualArchive(directory: directory, suiteName: suite, seedDemo: false)
        var record = RitualRecord.empty(now: now, calendar: calendar)
        record.onboardingComplete = true
        record = try XCTUnwrap(record.applying(.set(Set(line: "Kept.")), now: now, calendar: calendar).record)
        let token = await archive.nextGeneration()
        try await archive.save(record, generation: token)
        let reloaded = RitualArchive(directory: directory, suiteName: suite, seedDemo: false)
        let loaded = await reloaded.load(now: now)
        XCTAssertNil(loaded.notice)
        XCTAssertEqual(loaded.record.scroll.focus, .reflect)
        XCTAssertEqual(loaded.record.scroll.focused?.mark, .line(LineMark(text: "Kept.")))
        XCTAssertTrue(loaded.record.onboardingComplete)
        XCTAssertEqual(loaded.record.schemaVersion, 1)
        let mirrored = await archive.hasMirroredPayload()
        XCTAssertTrue(mirrored)

        let file = directory.appendingPathComponent("ritual.json")
        try Data("not-json".utf8).write(to: file, options: .atomic)
        let restored = await reloaded.load(now: now)
        XCTAssertEqual(restored.record.scroll.focused?.mark, .line(LineMark(text: "Kept.")))
        XCTAssertNotNil(restored.notice)

        let empty = try await reloaded.reset(now: now)
        XCTAssertTrue(empty.scroll.isUntouched)
        XCTAssertTrue(empty.nights.isEmpty)
        let afterReset = await reloaded.load(now: now)
        XCTAssertTrue(afterReset.record.nights.isEmpty)
        XCTAssertTrue(afterReset.record.scroll.isUntouched)
    }

    func testReviewLaunchParsesArguments() {
        XCTAssertEqual(ReviewLaunch.screen(from: ["Rotulus", "-ReviewScreen", "today"]), "today")
        XCTAssertEqual(ReviewLaunch.screen(from: ["Rotulus", "-ReviewScreen", "log"]), "log")
        XCTAssertEqual(ReviewLaunch.screen(from: ["Rotulus", "-ReviewScreen", "goals"]), "goals")
        XCTAssertNil(ReviewLaunch.screen(from: ["Rotulus"]))
        XCTAssertNil(ReviewLaunch.screen(from: ["Rotulus", "-ReviewScreen"]))
    }
}

private extension Result where Failure == ScrollRefusal, Success == Scroll {
    var scroll: Scroll? {
        if case .success(let value) = self { return value }
        return nil
    }

    var refusal: ScrollRefusal? {
        if case .failure(let error) = self { return error }
        return nil
    }
}

private extension Result where Failure == ScrollRefusal, Success == RitualRecord {
    var record: RitualRecord? {
        if case .success(let value) = self { return value }
        return nil
    }
}
