import SwiftUI

enum Theme {
    static let primary = Color(hex: 0x0D3B66)
    static let secondary = Color(hex: 0x00897B)
    static let lime = Color(hex: 0x7CB342)
    static let accent = Color(hex: 0xFFB300)
    static let background = Color(hex: 0xF6F8FB)
    static let textPrimary = Color(hex: 0x1F2937)
    static let textSecondary = Color(hex: 0x5B6573)
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

struct FilledButtonStyle: ButtonStyle {
    var color: Color = Theme.primary

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(color)
            )
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.5)
    }
}

struct OutlinedButtonStyle: ButtonStyle {
    var color: Color = Theme.primary

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color.opacity(0.6), lineWidth: 1.2)
            )
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.5)
    }
}

struct AppCard: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
            )
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

extension View {
    func appCard(padding: CGFloat = 16) -> some View {
        modifier(AppCard(padding: padding))
    }
}
