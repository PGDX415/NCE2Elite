//
//  LessonDataService.swift
//  NCE2Elite
//
//  Loads lesson metadata from the bundled lessons.json file.
//  For NCE2: 96 lessons, no unit grouping.
//

import Foundation

final class LessonDataService {
    /// All lessons loaded from the bundle.
    private(set) var lessons: [Lesson] = []

    /// Whether lessons have been successfully loaded.
    private(set) var isLoaded: Bool = false

    init() {
        loadLessons()
    }

    private func loadLessons() {
        guard let url = Bundle.main.url(forResource: "lessons", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("[LessonDataService] Failed to load lessons.json")
            return
        }

        do {
            lessons = try JSONDecoder().decode([Lesson].self, from: data)
                .sorted { $0.id < $1.id }
            isLoaded = true
        } catch {
            print("[LessonDataService] Failed to decode: \(error)")
        }
    }
}
