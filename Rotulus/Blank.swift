import Foundation

/// Blank is a night that was never touched. It is neither a gap in the streak
/// nor a sealed night. History does not list it as a rite.
struct Blank: Codable, Equatable, Sendable, Identifiable {
    var dayKey: Int

    var id: Int { dayKey }

    /// Writes Blank only for a scroll that still has every panel bare.
    static func written(dayKey: Int, scroll: Scroll) -> Blank? {
        guard scroll.dayKey == dayKey, scroll.isUntouched else { return nil }
        return Blank(dayKey: dayKey)
    }
}
