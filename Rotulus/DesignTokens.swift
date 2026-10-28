import SwiftUI

/// SPEC section 7. The only place these hex values live — reach colours
/// and the font family through here. Keep this file and its values.
enum DesignTokens {
    /// #151A1E
    static let bg = Color(red: 0.082353, green: 0.101961, blue: 0.117647)
    static let bgHex = "#151A1E"
    /// #1D252A
    static let surface = Color(red: 0.113725, green: 0.145098, blue: 0.164706)
    static let surfaceHex = "#1D252A"
    /// #EDF0F2
    static let ink = Color(red: 0.929412, green: 0.941176, blue: 0.949020)
    static let inkHex = "#EDF0F2"
    /// #58AAE4
    static let accent = Color(red: 0.345098, green: 0.666667, blue: 0.894118)
    static let accentHex = "#58AAE4"
    /// #92A0AA
    static let muted = Color(red: 0.572549, green: 0.627451, blue: 0.666667)
    static let mutedHex = "#92A0AA"
    static let fontFamily = "Helvetica"
}
