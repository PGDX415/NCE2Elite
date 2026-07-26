//
//  PlayerView.swift
//  NCE2Elite
//
//  Full-screen audio player with controls, progress, read-along text,
//  speed selection, loop mode, and sleep timer.
//

import SwiftUI

/// The main player screen displayed full-screen when a lesson is playing.
struct PlayerView: View {
    let viewModel: PlayerViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var showSpeedPicker = false
    @State private var showLoopPicker = false
    @State private var showSleepTimerPicker = false
    @State private var isDraggingSlider = false
    @State private var dragProgress: Double = 0

    private let speeds: [Float] = [0.75, 1.0, 1.25, 1.5]
    private let sleepOptions: [Int?] = [15, 30, 45, 60]

    var body: some View {
        ZStack {
            NCE2Colors.background
                .ignoresSafeArea()

            if viewModel.isReadAlongMode {
                readAlongContent
            } else {
                audioOnlyContent
            }

            // Countdown overlay
            if viewModel.isCountingDown {
                countdownOverlay
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    viewModel.stop()
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("返回")
                    }
                    .foregroundColor(NCE2Colors.oxfordBlue)
                }
            }

            ToolbarItem(placement: .principal) {
                Text("Lesson \(String(format: "%02d", viewModel.currentLessonNumber))")
                    .font(.system(.subheadline, design: .serif).bold())
                    .foregroundColor(NCE2Colors.textSecondary)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                SleepTimerBadge(
                    remaining: viewModel.sleepTimerRemaining,
                    onTap: { showSleepTimerPicker = true }
                )
            }
        }
        .confirmationDialog("倍速播放", isPresented: $showSpeedPicker) {
            ForEach(speeds, id: \.self) { speed in
                Button(String(format: "%.2fx", speed)) {
                    viewModel.setPlaybackRate(speed)
                }
            }
        }
        .confirmationDialog("循环模式", isPresented: $showLoopPicker) {
            ForEach(LoopMode.allCases, id: \.rawValue) { mode in
                Button(mode.rawValue) {
                    viewModel.setLoopMode(mode)
                }
            }
        }
        .confirmationDialog("睡眠定时器", isPresented: $showSleepTimerPicker) {
            ForEach(sleepOptions, id: \.self) { option in
                if let mins = option {
                    Button("\(mins) 分钟") {
                        viewModel.setSleepTimer(minutes: mins)
                    }
                }
            }
            Button("关闭定时器") {
                viewModel.setSleepTimer(minutes: nil)
            }
        }
    }

    // MARK: - Audio-Only Content

    private var audioOnlyContent: some View {
        VStack(spacing: 0) {
            Spacer()

            // Lesson info
            lessonInfoSection

            Spacer().frame(height: 40)

            // Progress and controls
            playbackControls

            Spacer()

            // Bottom toolbar
            bottomToolbar
                .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Read-Along Content

    private var readAlongContent: some View {
        VStack(spacing: 0) {
            // Mini player at top
            miniPlayer

            NCE2Divider()

            // Scrollable text
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(viewModel.displayEnglishText)
                        .font(.system(size: viewModel.textFontSize, design: .serif))
                        .foregroundColor(NCE2Colors.text)
                        .lineSpacing(6)

                    if !viewModel.displayChineseText.isEmpty {
                        NCE2Divider()
                            .padding(.vertical, 8)

                        Text(viewModel.displayChineseText)
                            .font(.system(size: viewModel.textFontSize - 2, design: .serif))
                            .foregroundColor(NCE2Colors.textSecondary)
                            .lineSpacing(6)
                    }
                }
                .padding(20)
            }
        }
    }

    // MARK: - Mini Player (Read-Along Mode)

    private var miniPlayer: some View {
        VStack(spacing: 8) {
            // Title
            Text(viewModel.currentLesson?.title ?? "")
                .font(.system(.headline, design: .serif))
                .foregroundColor(NCE2Colors.text)
                .lineLimit(1)

            // Progress
            VStack(spacing: 4) {
                progressSlider
                TimeLabels(current: viewModel.currentTime, total: viewModel.duration)
                    .padding(.horizontal, 4)
            }

            // Transport controls
            transportControls
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(NCE2Colors.card)
    }

    // MARK: - Lesson Info Section

    private var lessonInfoSection: some View {
        VStack(spacing: 8) {
            Text("Lesson \(String(format: "%02d", viewModel.currentLessonNumber))")
                .font(.system(.title3, design: .serif))
                .foregroundColor(NCE2Colors.oxfordBlue)

            Text(viewModel.currentLesson?.title ?? "")
                .nce2PlayerTitle()
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Playback Controls

    private var playbackControls: some View {
        VStack(spacing: 16) {
            // Progress slider
            VStack(spacing: 8) {
                progressSlider
                TimeLabels(current: viewModel.currentTime, total: viewModel.duration)
            }

            // Transport buttons
            transportControls
        }
        .padding(20)
        .background(NCE2Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Progress Slider

    private var progressSlider: some View {
        Slider(
            value: Binding(
                get: { isDraggingSlider ? dragProgress : viewModel.progress },
                set: { newValue in
                    dragProgress = newValue
                    viewModel.seek(to: newValue)
                }
            ),
            onEditingChanged: { editing in
                isDraggingSlider = editing
                if !editing {
                    viewModel.seek(to: dragProgress)
                }
            }
        )
        .tint(NCE2Colors.progressFill)
    }

    // MARK: - Transport Controls

    private var transportControls: some View {
        HStack(spacing: 28) {
            // Previous
            Button {
                viewModel.previousLesson()
            } label: {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: 24))
                    .foregroundColor(viewModel.hasPreviousLesson ? NCE2Colors.text : NCE2Colors.textSecondary.opacity(0.4))
            }
            .disabled(!viewModel.hasPreviousLesson)

            // Rewind 15s
            Button {
                viewModel.skipBackward()
            } label: {
                Image(systemName: "gobackward.15")
                    .font(.system(size: 24))
                    .foregroundColor(NCE2Colors.text)
            }

            // Play/Pause
            Button {
                viewModel.togglePlayPause()
            } label: {
                ZStack {
                    Circle()
                        .fill(NCE2Colors.oxfordBlue)
                        .frame(width: 64, height: 64)

                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
            }

            // Forward 15s
            Button {
                viewModel.skipForward()
            } label: {
                Image(systemName: "goforward.15")
                    .font(.system(size: 24))
                    .foregroundColor(NCE2Colors.text)
            }

            // Next
            Button {
                viewModel.nextLesson()
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 24))
                    .foregroundColor(viewModel.hasNextLesson ? NCE2Colors.text : NCE2Colors.textSecondary.opacity(0.4))
            }
            .disabled(!viewModel.hasNextLesson)
        }
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        HStack(spacing: 20) {
            // Read-along toggle
            Button {
                viewModel.toggleReadAlongMode()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: viewModel.isReadAlongMode ? "book.fill" : "book")
                        .font(.system(size: 18))
                    Text(viewModel.isReadAlongMode ? "只听" : "边听边看")
                        .font(.system(size: 10))
                }
                .foregroundColor(NCE2Colors.textSecondary)
            }

            Spacer()

            // Speed
            Button {
                showSpeedPicker = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "gauge.with.dots.needle.33percent")
                        .font(.system(size: 18))
                    Text(String(format: "%.2fx", viewModel.playbackRate))
                        .font(.system(size: 10))
                }
                .foregroundColor(NCE2Colors.textSecondary)
            }

            Spacer()

            // Loop mode
            Button {
                showLoopPicker = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: loopIcon)
                        .font(.system(size: 18))
                    Text(viewModel.loopMode.rawValue)
                        .font(.system(size: 10))
                }
                .foregroundColor(viewModel.loopMode != .none ? NCE2Colors.oxfordBlue : NCE2Colors.textSecondary)
            }

            Spacer()

            // Sleep timer
            Button {
                showSleepTimerPicker = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "moon.zzz")
                        .font(.system(size: 18))
                    Text("定时")
                        .font(.system(size: 10))
                }
                .foregroundColor(viewModel.sleepTimerActive ? NCE2Colors.sleepTimerActive : NCE2Colors.textSecondary)
            }
        }
        .padding(.horizontal, 20)
    }

    private var loopIcon: String {
        switch viewModel.loopMode {
        case .none: return "arrow.forward"
        case .single: return "repeat.1"
        case .list: return "repeat"
        }
    }

    // MARK: - Countdown Overlay

    private var countdownOverlay: some View {
        ZStack {
            NCE2Colors.background
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Lesson info
                VStack(spacing: 12) {
                    Text("Lesson \(String(format: "%02d", viewModel.currentLessonNumber))")
                        .font(.system(.title2, design: .serif))
                        .foregroundColor(NCE2Colors.oxfordBlue)

                    Text(viewModel.currentLesson?.title ?? "")
                        .font(.system(.title, design: .serif).bold())
                        .foregroundColor(NCE2Colors.text)
                        .multilineTextAlignment(.center)
                }

                Spacer().frame(height: 20)

                // Countdown number
                ZStack {
                    Circle()
                        .stroke(NCE2Colors.oxfordBlue.opacity(0.2), lineWidth: 4)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.countdownSeconds) / 4.0)
                        .stroke(NCE2Colors.oxfordBlue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: viewModel.countdownSeconds)

                    Text("\(viewModel.countdownSeconds)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(NCE2Colors.oxfordBlue)
                }

                Text("秒后开始播放")
                    .font(.system(.body, design: .serif))
                    .foregroundColor(NCE2Colors.textSecondary)

                Spacer()

                // Skip button
                Button {
                    viewModel.skipCountdown()
                } label: {
                    Text("立即播放")
                        .font(.system(.headline, design: .serif))
                        .foregroundColor(.white)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 14)
                        .background(NCE2Colors.oxfordBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Spacer().frame(height: 60)
            }
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    NavigationStack {
        PlayerView(viewModel: PlayerViewModel(
            audioService: AudioPlayerService(),
            importService: ImportService(),
            lessonDataService: LessonDataService()
        ))
    }
}
