import Foundation

/// Set is the verb that commits a LineMark on the focused Panel and folds that
/// panel from Bare to Marked. A second Set on the same panel is refused.
struct Set: Equatable, Sendable {
    var line: String

    var trimmed: String {
        line.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
