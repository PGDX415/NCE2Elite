//
//  Colors.swift
//  NCE2Elite
//
//  Design system color definitions with light/dark mode adaptive support.
//

import SwiftUI

// MARK: - Color Extension for Light/Dark Adaptive

extension Color {
    /// Create a Color that adapts between light and dark mode appearances.
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }

    /// Create a Color from hex string with adaptive support.
    init(lightHex: String, darkHex: String) {
        self.init(light: Color(hex: lightHex), dark: Color(hex: darkHex))
    }

    /// Initialize Color from hex string (e.g., "#1A3A6B" or "1A3A6B").
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }
}

// MARK: - NCE2 Color Palette

/// Centralized color definitions for the NCE2 Elite app.
/// All colors adapt to light/dark mode automatically.
enum NCE2Colors {
    // MARK: Background Colors

    /// Main background: light warm parchment / dark deep navy.
    static let background = Color(lightHex: "#F6F1E7", darkHex: "#0E1A2B")

    /// Card surface: light off-white / dark muted navy.
    static let card = Color(lightHex: "#FCFAF5", darkHex: "#1A2233")

    // MARK: Brand Colors

    /// Oxford Blue: classic academic navy base.
    static let oxfordBlue = Color(lightHex: "#1A3A6B", darkHex: "#4A8FE7")

    /// Antique Gold: elegant warm accent.
    static let antiqueGold = Color(lightHex: "#B8973F", darkHex: "#D4A843")

    /// Bordeaux: deep wine red for accent highlights.
    static let bordeaux = Color(hex: "#6E0F1A")

    // MARK: Text Colors

    /// Primary text: dark charcoal / warm off-white.
    static let text = Color(lightHex: "#1C1C1E", darkHex: "#E5E0D8")

    /// Secondary text: muted gray.
    static let textSecondary = Color(lightHex: "#5B6472", darkHex: "#9CA3AF")

    // MARK: Divider

    /// Separator lines: warm beige / dark slate.
    static let separator = Color(lightHex: "#D9D2C2", darkHex: "#2A3341")

    // MARK: Functional Colors

    /// Playback progress fill.
    static let progressFill = Color(lightHex: "#1A3A6B", darkHex: "#4A8FE7")

    /// Progress track background.
    static let progressTrack = Color(lightHex: "#D9D2C2", darkHex: "#2A3341")

    /// Favorite star active color.
    static let favoriteActive = Color(lightHex: "#B8973F", darkHex: "#D4A843")

    /// Favorite star inactive color.
    static let favoriteInactive = Color(lightHex: "#C4BFB3", darkHex: "#4A5568")

    /// Speed chip active background.
    static let speedChipActive = Color(lightHex: "#1A3A6B", darkHex: "#4A8FE7")

    /// Speed chip inactive background.
    static let speedChipInactive = Color(lightHex: "#E8E2D5", darkHex: "#2A3341")

    /// Sleep timer active color.
    static let sleepTimerActive = Color(lightHex: "#6E0F1A", darkHex: "#D4A843")
}
