//
//  AudioPlayerService.swift
//  NCE2Elite
//
//  Core audio playback service wrapping AVAudioPlayer.
//  Manages playback state, Now Playing info, remote commands,
//  loop mode, sleep timer, and background task management.
//

import AVFoundation
import MediaPlayer
import UIKit

// MARK: - Loop Mode

enum LoopMode: String, CaseIterable {
    case none = "不循环"
    case single = "单课循环"
    case list = "列表循环"
}

// MARK: - Delegate Protocol

protocol AudioPlayerServiceDelegate: AnyObject {
    func audioPlayerService(_ service: AudioPlayerService, didUpdatePlaybackTime currentTime: TimeInterval)
    func audioPlayerService(_ service: AudioPlayerService, didChangePlayingState isPlaying: Bool)
    func audioPlayerServiceDidFinishPlaying(_ service: AudioPlayerService)
    func audioPlayerService(_ service: AudioPlayerService, didUpdateDuration duration: TimeInterval)
}

// MARK: - Audio Player Service

@Observable
final class AudioPlayerService: NSObject {
    // MARK: - Delegate

    weak var delegate: AudioPlayerServiceDelegate?

    // MARK: - Player

    private var player: AVAudioPlayer?
    private var progressTimer: Timer?

    // MARK: - State

    private(set) var currentLesson: Lesson?
    private(set) var isPlaying: Bool = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var playbackRate: Float = 1.0
    var loopMode: LoopMode = .none

    // MARK: - Sleep Timer

    private var sleepTimer: Timer?
    private var sleepTimerEndDate: Date?
    private(set) var sleepTimerMinutes: Int?
    var sleepTimerRemaining: TimeInterval {
        guard let endDate = sleepTimerEndDate else { return 0 }
        return max(endDate.timeIntervalSinceNow, 0)
    }
    var sleepTimerActive: Bool { sleepTimerMinutes != nil }

    // MARK: - Background Task

    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid

    // MARK: - Computed

    var currentPosition: TimeInterval { player?.currentTime ?? 0 }

    // MARK: - Init

    override init() {
        super.init()
        setupRemoteCommands()
    }

    // MARK: - Playback

    func play(url: URL, lesson: Lesson, startAt position: TimeInterval = 0) {
        player?.stop()
        player?.delegate = nil

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.enableRate = true
            player?.prepareToPlay()
            player?.currentTime = min(position, player?.duration ?? 0)
            player?.rate = playbackRate
            player?.play()

            currentLesson = lesson
            isPlaying = true
            duration = player?.duration ?? 0
            currentTime = player?.currentTime ?? 0

            updateNowPlaying()
            startProgressTimer()
            startBackgroundTask()

            delegate?.audioPlayerService(self, didChangePlayingState: true)
            delegate?.audioPlayerService(self, didUpdateDuration: duration)
        } catch {
            print("[AudioPlayerService] Failed to play: \(error)")
        }
    }

    func resume() {
        guard let player else { return }
        player.play()
        isPlaying = true
        startProgressTimer()
        startBackgroundTask()
        updateNowPlaying()
        delegate?.audioPlayerService(self, didChangePlayingState: true)
    }

    func pause() {
        guard let player else { return }
        player.pause()
        isPlaying = false
        stopProgressTimer()
        endBackgroundTask()
        updateNowPlaying()
        delegate?.audioPlayerService(self, didChangePlayingState: false)
    }

    func togglePlayPause() {
        isPlaying ? pause() : resume()
    }

    func seek(to time: TimeInterval) {
        guard let player else { return }
        player.currentTime = max(0, min(time, player.duration))
        currentTime = player.currentTime
        updateNowPlaying()
    }

    func skipForward(seconds: TimeInterval = 15) {
        guard let player else { return }
        let newTime = min(player.currentTime + seconds, player.duration)
        seek(to: newTime)
    }

    func skipBackward(seconds: TimeInterval = 15) {
        guard let player else { return }
        let newTime = max(player.currentTime - seconds, 0)
        seek(to: newTime)
    }

    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        player?.rate = rate
    }

    func setLoopMode(_ mode: LoopMode) {
        loopMode = mode
    }

    func stop() {
        player?.stop()
        player = nil
        currentLesson = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        stopProgressTimer()
        cancelSleepTimer()
        endBackgroundTask()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    // MARK: - Progress Timer

    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self, let player = self.player else { return }
            self.currentTime = player.currentTime
            self.delegate?.audioPlayerService(self, didUpdatePlaybackTime: player.currentTime)
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    // MARK: - Sleep Timer

    func setSleepTimer(minutes: Int?) {
        cancelSleepTimer()
        guard let minutes = minutes else { return }
        sleepTimerMinutes = minutes
        sleepTimerEndDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
        sleepTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(minutes * 60), repeats: false) { [weak self] _ in
            self?.pause()
            self?.cancelSleepTimer()
        }
    }

    func cancelSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        sleepTimerMinutes = nil
        sleepTimerEndDate = nil
    }

    // MARK: - Background Task

    private func startBackgroundTask() {
        endBackgroundTask()
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        guard backgroundTaskID != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
    }

    // MARK: - Now Playing Info

    private func updateNowPlaying() {
        guard let player else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: currentLesson?.title ?? "NCE2",
            MPMediaItemPropertyArtist: "Lesson \(currentLesson?.lessonNumber ?? 0)",
            MPMediaItemPropertyPlaybackDuration: player.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? playbackRate : 0,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0
        ]
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // MARK: - Remote Commands

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            self?.resume(); return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.pause(); return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause(); return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self, let evt = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self.seek(to: evt.positionTime)
            return .success
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayerService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard flag else { return }
        isPlaying = false
        currentTime = player.duration
        stopProgressTimer()
        endBackgroundTask()
        delegate?.audioPlayerServiceDidFinishPlaying(self)
    }
}
