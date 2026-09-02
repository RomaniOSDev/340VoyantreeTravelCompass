import SwiftUI

enum AppTheme {
    static let background = Color("AppBackground")
    static let surface = Color("AppSurface")
    static let primary = Color("AppPrimary")
    static let accent = Color("AppAccent")

    static var goldLift: LinearGradient {
        LinearGradient(
            colors: [primary.opacity(0.95), accent.opacity(0.75)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var nightPanel: LinearGradient {
        LinearGradient(
            colors: [surface.opacity(0.96), background.opacity(0.88)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var placeTitle: Font {
        .system(.title3, design: .serif).weight(.semibold)
    }

    static var displayTitle: Font {
        .system(.title, design: .serif).weight(.bold)
    }

    static var trackedLabel: Font {
        .system(size: 11, weight: .semibold, design: .rounded)
    }
}

struct GoldPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .offset(y: configuration.isPressed ? 1 : 0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
