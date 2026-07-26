//
//  Lesson.swift
//  NCE2Elite
//
//  Data model for a single NCE2 lesson (96 lessons, flat list, no units).
//

import Foundation

/// Represents a single lesson from New Concept English Book 2.
struct Lesson: Identifiable, Codable, Equatable {
    let id: Int                 // 1–96
    let lessonNumber: Int       // 1–96 (alias for id, retained for display)
    let title: String
    let audioFileName: String   // "Lesson01"
    var englishText: String?    // Embedded English text (dev phase)
    var chineseText: String?    // Embedded Chinese text (dev phase)
    /// Runtime-only, filled by audio player; not decoded from JSON.
    var durationSeconds: Double = 0

    enum CodingKeys: String, CodingKey {
        case id, lessonNumber, title, audioFileName, englishText, chineseText
    }

    /// Formatted two-digit lesson number string, e.g. "01".
    var formattedLessonNumber: String {
        String(format: "%02d", lessonNumber)
    }

    static func == (lhs: Lesson, rhs: Lesson) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Preview

extension Lesson {
    static let preview = Lesson(
        id: 1,
        lessonNumber: 1,
        title: "A Private Conversation",
        audioFileName: "Lesson01",
        englishText: "Last week I went to the theatre...",
        chineseText: "上星期我去看戏...",
        durationSeconds: 87
    )
}
