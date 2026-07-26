//
//  FavoritesViewModel.swift
//  NCE2Elite
//
//  ViewModel for the favorites tab.
//

import SwiftUI
import SwiftData

@Observable
final class FavoritesViewModel {
    private let lessonDataService: LessonDataService
    private let importService: ImportService
    private var modelContext: ModelContext?

    init(lessonDataService: LessonDataService, importService: ImportService) {
        self.lessonDataService = lessonDataService
        self.importService = importService
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    var allLessons: [Lesson] { lessonDataService.lessons }

    var favoriteLessons: [Lesson] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<LessonProgress>(predicate: #Predicate { $0.isFavorite == true })
        guard let favorites = try? context.fetch(descriptor) else { return [] }
        let ids = Set(favorites.map { $0.lessonId })
        return allLessons.filter { ids.contains($0.id) }
    }

    func isAudioAvailable(for lesson: Lesson) -> Bool {
        importService.isAudioAvailable(for: lesson)
    }

    func progress(for lessonId: Int) -> Double {
        guard let context = modelContext else { return 0 }
        let descriptor = FetchDescriptor<LessonProgress>(predicate: #Predicate { $0.lessonId == lessonId })
        guard let progress = try? context.fetch(descriptor).first else { return 0 }
        if progress.isCompleted { return 1.0 }
        let position = progress.lastPlayedPosition
        guard position > 0, let lesson = allLessons.first(where: { $0.id == lessonId }) else { return 0 }
        let duration = importService.audioDuration(for: lesson)
        guard duration > 0 else { return 0 }
        return min(position / duration, 1.0)
    }

    func toggleFavorite(for lessonId: Int) {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<LessonProgress>(predicate: #Predicate { $0.lessonId == lessonId })
        if let existing = try? context.fetch(descriptor).first {
            existing.isFavorite.toggle()
        }
        try? context.save()
    }
}
