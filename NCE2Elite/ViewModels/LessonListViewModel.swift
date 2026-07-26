//
//  LessonListViewModel.swift
//  NCE2Elite
//
//  ViewModel for the lesson list screen.
//  Handles searching, filtering, favorite caching, and import status.
//

import SwiftUI
import SwiftData

@Observable
final class LessonListViewModel {
    // MARK: - Dependencies

    private let lessonDataService: LessonDataService
    private let importService: ImportService
    private var modelContext: ModelContext?

    // MARK: - State

    var searchText = ""
    private(set) var favoriteLessonIDs: Set<Int> = []

    // MARK: - Computed

    var allLessons: [Lesson] { lessonDataService.lessons }

    var filteredLessons: [Lesson] {
        let lessons = allLessons
        guard !searchText.isEmpty else { return lessons }
        let query = searchText.lowercased()
        return lessons.filter { lesson in
            String(lesson.lessonNumber).contains(query) ||
            lesson.title.lowercased().contains(query) ||
            lesson.formattedLessonNumber.lowercased().contains(query)
        }
    }

    var isLoaded: Bool { lessonDataService.isLoaded }

    // MARK: - Jump Bar Anchors

    /// Quick-jump: every 16 lessons (1, 17, 33, 49, 65, 81).
    var jumpAnchors: [Int] {
        stride(from: 1, through: 96, by: 16).map { $0 }
    }

    // MARK: - Initialization

    init(lessonDataService: LessonDataService, importService: ImportService) {
        self.lessonDataService = lessonDataService
        self.importService = importService
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        refreshFavorites()
    }

    // MARK: - Public API

    func isAudioAvailable(for lesson: Lesson) -> Bool {
        importService.isAudioAvailable(for: lesson)
    }

    func toggleFavorite(for lessonId: Int) {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<LessonProgress>(predicate: #Predicate { $0.lessonId == lessonId })
        if let existing = try? context.fetch(descriptor).first {
            existing.isFavorite.toggle()
            if existing.isFavorite { favoriteLessonIDs.insert(lessonId) }
            else { favoriteLessonIDs.remove(lessonId) }
        } else {
            let progress = LessonProgress(lessonId: lessonId, isFavorite: true)
            context.insert(progress)
            favoriteLessonIDs.insert(lessonId)
        }
        try? context.save()
    }

    func isFavorite(_ lessonId: Int) -> Bool {
        favoriteLessonIDs.contains(lessonId)
    }

    func progress(for lessonId: Int) -> Double {
        guard let context = modelContext else { return 0 }
        let descriptor = FetchDescriptor<LessonProgress>(predicate: #Predicate { $0.lessonId == lessonId })
        guard let progress = try? context.fetch(descriptor).first else { return 0 }
        if progress.isCompleted { return 1.0 }

        let position = progress.lastPlayedPosition
        guard position > 0 else { return 0 }

        guard let lesson = allLessons.first(where: { $0.id == lessonId }) else { return 0 }
        let duration = importService.audioDuration(for: lesson)
        guard duration > 0 else { return 0 }

        return min(position / duration, 1.0)
    }

    func refreshFavorites() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<LessonProgress>(predicate: #Predicate { $0.isFavorite == true })
        if let favorites = try? context.fetch(descriptor) {
            favoriteLessonIDs = Set(favorites.map { $0.lessonId })
        }
    }

    var importedLessonIDs: Set<Int> {
        importService.importedLessonIDs()
    }
}
