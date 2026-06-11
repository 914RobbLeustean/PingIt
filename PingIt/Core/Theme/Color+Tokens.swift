import SwiftUI

extension Color {
    static let pingBackground       = Color(hex: 0x090912)
    static let pingSurface          = Color(hex: 0x12121C)
    static let pingSurfaceElevated  = Color(hex: 0x1A1A28)
    static let pingBorder           = Color(white: 1, opacity: 0.07)
    static let pingTextPrimary      = Color(hex: 0xF0F0F8)
    static let pingTextSecondary    = Color(hex: 0x6B6B84)
    static let pingAccent           = Color(hex: 0xF5A623)
    static let pingHot              = Color(hex: 0xE03828)
    static let pingLive             = Color(hue: 0.39, saturation: 0.72, brightness: 0.82)
}

extension Color {
    fileprivate init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
