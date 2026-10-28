import Foundation

/// NightMark is a sealed night. History and streak read these marks only.
/// Sleep duration is never stored and never estimated.
struct NightMark: Codable, Equatable, Sendable, Identifiable {
    var dayKey: Int
    var reflect: String?
    var breathe: String?
    var ambient: String?
    var sealedAt: Date

    var id: Int { dayKey }

    init(dayKey: Int, reflect: String?, breathe: String?, ambient: String?, sealedAt: Date) {
        self.dayKey = dayKey
        self.reflect = reflect
        self.breathe = breathe
        self.ambient = ambient
        self.sealedAt = sealedAt
    }

    init(scroll: Scroll, sealedAt: Date) {
        let panels = scroll.panels
        self.init(
            dayKey: scroll.dayKey,
            reflect: panels.count > 0 ? panels[0].mark?.lineText : nil,
            breathe: panels.count > 1 ? panels[1].mark?.lineText : nil,
            ambient: panels.count > 2 ? panels[2].mark?.lineText : nil,
            sealedAt: sealedAt
        )
    }
}
