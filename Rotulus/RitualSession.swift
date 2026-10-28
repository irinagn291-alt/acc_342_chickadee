import Foundation
import SwiftUI

/// RitualSession is the state between the record and the screens.
/// Views send Set, Waft, Furl, and Roll here. They never touch the archive.
/// Saves debounce about 300ms and flush when the scene leaves the foreground.

@MainActor
@Observable
final class RitualSession {
    private(set) var record: RitualRecord
    private(set) var notice: String?
    private(set) var refusal: ScrollRefusal?
    private(set) var lastNight: NightMark?
    private let archive: RitualArchive
    private var saveTask: Task<Void, Never>?

    init(record: RitualRecord, notice: String?, archive: RitualArchive) {
        self.record = record
        self.notice = notice
        self.archive = archive
    }

    static func open(archive: RitualArchive, now: Date = Date()) async -> RitualSession {
        let loaded = await archive.load(now: now)
        return RitualSession(record: loaded.record, notice: loaded.notice, archive: archive)
    }

    static func openLive() async -> RitualSession {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let directory = (base ?? FileManager.default.temporaryDirectory)
            .appendingPathComponent("Chickadee", isDirectory: true)
        #if targetEnvironment(simulator)
        let seedDemo = true
        #else
        let seedDemo = false
        #endif
        let archive = RitualArchive(directory: directory, defaults: .standard, seedDemo: seedDemo)
        return await open(archive: archive)
    }

    func setLine(_ line: String, now: Date = Date()) {
        commit(.set(Set(line: line)), now: now)
    }

    func waft(now: Date = Date()) {
        commit(.waft, now: now)
    }

    func furl(now: Date = Date()) {
        commit(.furl(Furl()), now: now)
    }

    func roll(now: Date = Date()) {
        commit(.roll(RollMark(sealedAt: now)), now: now)
    }

    func finishOnboarding() {
        record.onboardingComplete = true
        scheduleSave()
    }

    func updateDurations(reflect: TimeInterval, breathe: TimeInterval, ambient: TimeInterval) {
        record.reflectSeconds = reflect
        record.breatheSeconds = breathe
        record.ambientSeconds = ambient
        scheduleSave()
    }

    func setHaptics(_ enabled: Bool) {
        record.hapticsEnabled = enabled
        scheduleSave()
    }

    func resetAllData(now: Date = Date()) async {
        saveTask?.cancel()
        saveTask = nil
        do {
            record = try await archive.reset(now: now)
            notice = nil
            refusal = nil
            lastNight = nil
        } catch is CancellationError {
            return
        } catch {
            notice = "Reset failed. Local data is still on this device."
        }
    }

    func flush() async {
        saveTask?.cancel()
        saveTask = nil
        let snapshot = record
        let token = await archive.nextGeneration()
        do {
            try await archive.save(snapshot, generation: token)
        } catch is CancellationError {
            return
        } catch {
            notice = "The night is on screen. The save did not land."
        }
    }

    func noteScene(_ phase: ScenePhase) {
        guard phase == .inactive || phase == .background else { return }
        saveTask?.cancel()
        saveTask = nil
        let snapshot = record
        Task {
            let token = await archive.nextGeneration()
            do {
                try await archive.save(snapshot, generation: token)
            } catch is CancellationError {
                return
            } catch {
                notice = "The night is on screen. The save did not land."
            }
        }
    }

    private func commit(_ verb: ScrollVerb, now: Date) {
        switch record.applying(verb, now: now) {
        case .failure(let error):
            refusal = error
        case .success(let next):
            refusal = nil
            record = next
            if case .roll = verb, let night = next.nights.last {
                lastNight = night
            }
            scheduleSave()
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        let snapshot = record
        saveTask = Task {
            let token = await archive.nextGeneration()
            do {
                try await Task.sleep(for: .milliseconds(300))
            } catch {
                return
            }
            do {
                try await archive.save(snapshot, generation: token)
            } catch is CancellationError {
                return
            } catch {
                notice = "The night is on screen. The save did not land."
            }
        }
    }
}
