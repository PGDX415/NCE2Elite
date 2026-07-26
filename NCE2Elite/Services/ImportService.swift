//
//  ImportService.swift
//  NCE2Elite
//
//  Manages user-imported audio files, text files, and audio duration caching.
//  Playback priority: user-imported > bundle (development fallback).
//

import Foundation
import AVFoundation

@Observable
final class ImportService {
    /// Development mode: all 96 lessons available from bundle.
    /// For App Store release, change to `Set([1, 2])`.
    static let sampleLessonIDs: Set<Int> = Set(1...96)

    /// Cached audio durations for real progress calculation.
    private var audioDurationCache: [Int: Double] = [:]

    private let fileManager = FileManager.default

    // MARK: - Directories

    var importedAudioDirectory: URL {
        documentsDirectory.appendingPathComponent("ImportedAudio")
    }

    var importedTextsDirectory: URL {
        documentsDirectory.appendingPathComponent("ImportedTexts")
    }

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    init() {
        createDirectoriesIfNeeded()
    }

    private func createDirectoriesIfNeeded() {
        try? fileManager.createDirectory(at: importedAudioDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: importedTextsDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Audio Availability

    func isAudioAvailable(for lesson: Lesson) -> Bool {
        userImportedAudioURL(for: lesson.id) != nil
            || (Self.sampleLessonIDs.contains(lesson.id) && bundleAudioURL(for: lesson.id) != nil)
    }

    func audioURL(for lesson: Lesson) -> URL? {
        if let userURL = userImportedAudioURL(for: lesson.id) {
            return userURL
        }
        if Self.sampleLessonIDs.contains(lesson.id) {
            return bundleAudioURL(for: lesson.id)
        }
        return nil
    }

    private func userImportedAudioURL(for lessonId: Int) -> URL? {
        let url = importedAudioDirectory.appendingPathComponent("Lesson\(String(format: "%02d", lessonId)).mp3")
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    private func bundleAudioURL(for lessonId: Int) -> URL? {
        Bundle.main.url(forResource: "Lesson\(String(format: "%02d", lessonId))", withExtension: "mp3")
    }

    // MARK: - Text Import

    func loadImportedText(for lesson: Lesson) -> (english: String, chinese: String)? {
        let url = importedTextsDirectory.appendingPathComponent("Lesson\(String(format: "%02d", lesson.id)).json")
        guard fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String]
        else { return nil }
        return (json["englishText"] ?? "", json["chineseText"] ?? "")
    }

    // MARK: - Audio Duration

    func audioDuration(for lesson: Lesson) -> Double {
        if let cached = audioDurationCache[lesson.id] { return cached }
        return 0
    }

    func loadAudioDuration(for lessonId: Int) async -> Double {
        if let cached = audioDurationCache[lessonId] { return cached }
        guard let url = audioURL(forID: lessonId) else { return 0 }
        let asset = AVURLAsset(url: url)
        do {
            let cmDuration = try await asset.load(.duration)
            let dur = CMTimeGetSeconds(cmDuration)
            guard dur.isFinite && dur > 0 else { return 0 }
            audioDurationCache[lessonId] = dur
            return dur
        } catch {
            return 0
        }
    }

    private func audioURL(forID lessonId: Int) -> URL? {
        if let userURL = userImportedAudioURL(for: lessonId) { return userURL }
        if Self.sampleLessonIDs.contains(lessonId) { return bundleAudioURL(for: lessonId) }
        return nil
    }

    func preloadAllDurations() async {
        let ids = Array(1...96)
        for chunk in ids.chunked(into: 4) {
            await withTaskGroup(of: Void.self) { group in
                for id in chunk {
                    group.addTask { _ = await self.loadAudioDuration(for: id) }
                }
            }
        }
    }

    func clearDurationCache() {
        audioDurationCache.removeAll()
    }

    // MARK: - Import Management

    func importAudioFiles(from urls: [URL]) throws -> Int {
        var count = 0
        for url in urls {
            guard url.pathExtension.lowercased() == "mp3" else { continue }
            let dest = importedAudioDirectory.appendingPathComponent(url.lastPathComponent)
            if fileManager.fileExists(atPath: dest.path) { try fileManager.removeItem(at: dest) }
            try fileManager.copyItem(at: url, to: dest)
            count += 1
        }
        clearDurationCache()
        return count
    }

    func importTextFiles(from urls: [URL]) throws -> Int {
        var count = 0
        for url in urls {
            guard url.pathExtension.lowercased() == "json" else { continue }
            let dest = importedTextsDirectory.appendingPathComponent(url.lastPathComponent)
            if fileManager.fileExists(atPath: dest.path) { try fileManager.removeItem(at: dest) }
            try fileManager.copyItem(at: url, to: dest)
            count += 1
        }
        return count
    }

    func importedLessonIDs() -> Set<Int> {
        guard let files = try? fileManager.contentsOfDirectory(at: importedAudioDirectory, includingPropertiesForKeys: nil)
        else { return [] }
        return Set(files.compactMap { url in
            let name = url.deletingPathExtension().lastPathComponent
            guard name.hasPrefix("Lesson"), let num = Int(name.replacingOccurrences(of: "Lesson", with: ""))
            else { return nil }
            return num
        })
    }
}

// MARK: - Array Chunk

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
