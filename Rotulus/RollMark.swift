import Foundation

/// RollMark is the seal request. Roll accepts it only when every Panel is
/// marked, then folds the scroll from Marked to Rolled and writes a NightMark.
struct RollMark: Equatable, Sendable {
    var sealedAt: Date

    init(sealedAt: Date) {
        self.sealedAt = sealedAt
    }
}
