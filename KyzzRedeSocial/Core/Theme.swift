import SwiftUI

enum Theme {
    static let primary = Color(hex: 0x0D3B66)
    static let accent = Color(hex: 0x33B492)
    static let background = Color.white
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}
