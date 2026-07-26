//
//  Typography.swift
//  NCE2Elite
//
//  Centralized typography system for the NCE2 Elite app.
//

import SwiftUI

/// Unified typography manager for all text styles in NCE2 Elite.
/// Uses system serif for academic elegance with monospaced digits for durations.
enum NCE2Typography {
    // MARK: - Font Styles

    /// Brand title: large serif, used for app name in header.
    /// ~28pt, bold, serif
    static func brandTitle() -> Font {
        .system(.title, design: .serif).bold()
    }

    /// Player title: medium-large, used for current lesson title in player.
    /// ~22pt, semibold, serif
    static func playerTitle() -> Font {
        .system(.title2, design: .serif).weight(.semibold)
    }

    /// Lesson title: used in list row for lesson name.
    /// ~17pt, medium, serif
    static func lessonTitle() -> Font {
        .system(.body, design: .serif).weight(.medium)
    }

    /// List header: used for section headers if needed.
    /// ~20pt, bold, serif
    static func listHeader() -> Font {
        .system(.title3, design: .serif).bold()
    }

    /// Body text: standard reading size.
    /// ~16pt, regular, serif
    static func body() -> Font {
        .system(.body, design: .serif)
    }

    /// Caption: small secondary info, metadata.
    /// ~13pt, regular
    static func caption() -> Font {
        .system(.caption, design: .default)
    }

    /// Custom-sized body text for read-along mode.
    static func body(size: CGFloat) -> Font {
        .system(size: size, design: .serif)
    }

    /// Mono digit: for duration, timestamps, counters.
    /// ~15pt, monospaced digit
    static func monoDigit() -> Font {
        .system(.subheadline, design: .monospaced).monospacedDigit()
    }

    // MARK: - Text View Modifiers

    struct BrandTitleModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(NCE2Typography.brandTitle())
                .foregroundColor(NCE2Colors.text)
        }
    }

    struct PlayerTitleModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(NCE2Typography.playerTitle())
                .foregroundColor(NCE2Colors.text)
        }
    }

    struct LessonTitleModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(NCE2Typography.lessonTitle())
                .foregroundColor(NCE2Colors.text)
        }
    }

    struct BodyModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(NCE2Typography.body())
                .foregroundColor(NCE2Colors.text)
        }
    }

    struct CaptionModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(NCE2Typography.caption())
                .foregroundColor(NCE2Colors.textSecondary)
        }
    }

    struct MonoDigitModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(NCE2Typography.monoDigit())
                .foregroundColor(NCE2Colors.textSecondary)
        }
    }
}

// MARK: - Convenience View Extensions

extension View {
    func nce2BrandTitle() -> some View {
        modifier(NCE2Typography.BrandTitleModifier())
    }

    func nce2PlayerTitle() -> some View {
        modifier(NCE2Typography.PlayerTitleModifier())
    }

    func nce2LessonTitle() -> some View {
        modifier(NCE2Typography.LessonTitleModifier())
    }

    func nce2Body() -> some View {
        modifier(NCE2Typography.BodyModifier())
    }

    func nce2Caption() -> some View {
        modifier(NCE2Typography.CaptionModifier())
    }

    func nce2MonoDigit() -> some View {
        modifier(NCE2Typography.MonoDigitModifier())
    }
}
