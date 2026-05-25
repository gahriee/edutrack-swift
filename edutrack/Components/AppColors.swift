import SwiftUI

enum AppColors {
    // Brand
    static let primary        = Color(hex: 0x2563EB)
    static let primaryDark    = Color(hex: 0x3B82F6)
    static let secondary      = Color(hex: 0x0EA5E9)

    // Backgrounds
    static let background     = Color(hex: 0xF1F5F9)
    static let backgroundDark = Color(hex: 0x0F172A)
    static let surface        = Color(hex: 0xFFFFFF)
    static let surfaceDark    = Color(hex: 0x1E293B)

    // Text
    static let textPrimary    = Color(hex: 0x0F172A)
    static let textSecondary  = Color(hex: 0x64748B)

    // Borders
    static let outline        = Color(hex: 0xCBD5E1)

    // Attendance
    static let present        = Color(hex: 0x16A34A)
    static let absent         = Color(hex: 0xDC2626)
    static let late           = Color(hex: 0xD97706)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >>  8) & 0xFF) / 255,
            blue:  Double( hex        & 0xFF) / 255
        )
    }
}
