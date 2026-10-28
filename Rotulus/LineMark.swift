import Foundation

/// LineMark is the one trimmed release line Set writes on the focused Panel.
struct LineMark: Codable, Equatable, Sendable {
    var text: String

    init(text: String) {
        self.text = text
    }
}
