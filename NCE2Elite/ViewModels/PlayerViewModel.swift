//
//  PlayerViewModel.swift
//  NCE2Elite
//
//  ViewModel bridging AudioPlayerService to the UI.
//  Manages playback state, progress persistence, read-along toggle,
//  and navigation between lessons.
//

import SwiftUI
import SwiftData

@Observable
final class PlayerViewModel {
    // MARK: - Dependencies

    private let audioService: AudioPlayerService
    private let importService: ImportService
    private let lessonDataService: LessonDataService
    private var modelContext: ModelContext?

    // MARK: - State

    private(set) var currentLesson: Lesson?
    var isPlaying: Bool { audioService.isPlaying }
    var currentTime: TimeInterval { audioService.currentTime }
    var duration: TimeInterval { audioService.duration }
    var playbackRate: Float { audioService.playbackRate }
    var loopMode: LoopMode { audioService.loopMode }
    var sleepTimerRemaining: TimeInterval { audioService.sleepTimerRemaining }
    var sleepTimerActive: Bool { audioService.sleepTimerActive }

    /// Display mode: true = read-along, false = audio-only.
    var isReadAlongMode = false

    /// Font size for text display (pt).
    var textFontSize: Double {
        get {
            let stored = UserDefaults.standard.double(forKey: "lessonFontSize")
            return stored > 0 ? stored : 16
        }
        set { UserDefaults.standard.set(newValue, forKey: "lessonFontSize") }
    }

    /// Countdown seconds before playback (0 = not counting down).
    private(set) var countdownSeconds: Int = 0
    var isCountingDown: Bool { countdownSeconds > 0 }

    /// Imported text for current lesson (from user import, overrides bundle).
    private(set) var importedText: (english: String, chinese: String)?

    /// All available lessons for navigation.
    var allLessons: [Lesson] { lessonDataService.lessons }

    /// Countdown task for cancellation.
    private var countdownTask: Task<Void, Never>?

    // MARK: - Computed

    /// Progress as a fraction (0.0 to 1.0).
    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(currentTime / duration, 1.0)
    }

    var currentLessonNumber: Int { currentLesson?.lessonNumber ?? 0 }

    var displayEnglishText: String {
        importedText?.english ?? currentLesson?.englishText ?? ""
    }

    var displayChineseText: String {
        importedText?.chinese ?? currentLesson?.chineseText ?? ""
    }

    var hasTextContent: Bool { !displayEnglishText.isEmpty }

    private var currentIndex: Int? {
        guard let lesson = currentLesson else { return nil }
        return allLessons.firstIndex { $0.id == lesson.id }
    }

    var hasPreviousLesson: Bool {
        guard let idx = currentIndex else { return false }
        return idx > 0
    }

    var hasNextLesson: Bool {
        guard let idx = currentIndex else { return false }
        return idx < allLessons.count - 1
    }

    // MARK: - Initialization

    init(
        audioService: AudioPlayerService,
        importService: ImportService,
        lessonDataService: LessonDataService
    ) {
        self.audioService = audioService
        self.importService = importService
        self.lessonDataService = lessonDataService
        self.audioService.delegate = self
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Playback Controls

    private static let countdownDuration = 4

    func play(lesson: Lesson) {
        cancelCountdown()
        audioService.stop()

        guard let url = importService.audioURL(for: lesson) else {
            print("[PlayerViewModel] No audio for Lesson \(lesson.lessonNumber)")
            return
        }

        currentLesson = lesson
        importedText = importService.loadImportedText(for: lesson)
        isReadAlongMode = false

        let savedPosition = loadProgress(for: lesson.id)?.lastPlayedPosition ?? 0
        countdownSeconds = Self.countdownDuration

        countdownTask = Task { [weak self] in
            guard let self else { return }
            for second in (1...Self.countdownDuration).reversed() {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run { self.countdownSeconds = second - 1 }
            }
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.audioService.play(url: url, lesson: lesson, startAt: savedPosition)
            }
        }
    }

    func skipCountdown() {
        guard isCountingDown, let lesson = currentLesson else { return }
        cancelCountdown()
        let savedPosition = loadProgress(for: lesson.id)?.lastPlayedPosition ?? 0
        guard let url = importService.audioURL(for: lesson) else { return }
        audioService.play(url: url, lesson: lesson, startAt: savedPosition)
    }

    func cancelCountdown() {
        countdownTask?.cancel()
        countdownTask = nil
        countdownSeconds = 0
    }

    func togglePlayPause() {
        audioService.togglePlayPause()
    }

    func stop() {
        cancelCountdown()
        saveProgress()
        audioService.stop()
    }

    /// Seek to position from slider (0...1).
    func seek(to fraction: Double) {
        let time = fraction * duration
        audioService.seek(to: time)
    }

    func skipForward() { audioService.skipForward(seconds: 15) }
    func skipBackward() { audioService.skipBackward(seconds: 15) }

    func previousLesson() {
        guard let idx = currentIndex, idx > 0 else { return }
        play(lesson: allLessons[idx - 1])
    }

    func nextLesson() {
        guard let idx = currentIndex, idx < allLessons.count - 1 else { return }
        play(lesson: allLessons[idx + 1])
    }

    func setPlaybackRate(_ rate: Float) { audioService.setPlaybackRate(rate) }
    func setLoopMode(_ mode: LoopMode) { audioService.setLoopMode(mode) }

    func setSleepTimer(minutes: Int?) {
        if let minutes = minutes { audioService.setSleepTimer(minutes: minutes) }
        else { audioService.cancelSleepTimer() }
    }

    func toggleReadAlongMode() { isReadAlongMode.toggle() }

    // MARK: - Progress Persistence

    func saveProgress() {
        guard let lessonId = currentLesson?.id, let context = modelContext else { return }
        let position = audioService.currentPosition
        let descriptor = FetchDescriptor<LessonProgress>(predicate: #Predicate { $0.lessonId == lessonId })
        if let existing = try? context.fetch(descriptor).first {
            existing.lastPlayedPosition = position
            existing.lastPlayedDate = Date()
            existing.isCompleted = (position >= duration - 2 && duration > 0)
        } else {
            let progress = LessonProgress(
                lessonId: lessonId, lastPlayedPosition: position,
                isCompleted: (position >= duration - 2 && duration > 0),
                lastPlayedDate: Date()
            )
            context.insert(progress)
        }
        try? context.save()
    }

    func loadProgress(for lessonId: Int) -> LessonProgress? {
        guard let context = modelContext else { return nil }
        let descriptor = FetchDescriptor<LessonProgress>(predicate: #Predicate { $0.lessonId == lessonId })
        return try? context.fetch(descriptor).first
    }
}

// MARK: - AudioPlayerServiceDelegate

extension PlayerViewModel: AudioPlayerServiceDelegate {
    func audioPlayerService(_ service: AudioPlayerService, didUpdatePlaybackTime currentTime: TimeInterval) {}
    func audioPlayerService(_ service: AudioPlayerService, didChangePlayingState isPlaying: Bool) {}

    func audioPlayerServiceDidFinishPlaying(_ service: AudioPlayerService) {
        saveProgress()
        switch service.loopMode {
        case .single:
            if let lesson = currentLesson { play(lesson: lesson) }
        case .list:
            if let idx = currentIndex, idx < allLessons.count - 1 {
                play(lesson: allLessons[idx + 1])
            } else if !allLessons.isEmpty {
                play(lesson: allLessons[0])
            }
        case .none: break
        }
    }

    func audioPlayerService(_ service: AudioPlayerService, didUpdateDuration duration: TimeInterval) {}
}
