//
//  NCE2EliteComponents.swift
//  NCE2Elite
//
//  Reusable UI components for the NCE2 Elite app.
//

import SwiftUI

// MARK: - Favorite Star Button

/// A star button for toggling favorite status with animated gold fill.
struct FavoriteStarButton: View {
    let isFavorite: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                action()
            }
        }) {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.system(size: 20))
                .foregroundColor(isFavorite ? NCE2Colors.favoriteActive : NCE2Colors.favoriteInactive)
                .scaleEffect(isFavorite ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFavorite)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Lesson Progress Bar

/// A thin progress bar showing playback completion percentage.
struct LessonProgressBar: View {
    let progress: Double // 0.0 to 1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(NCE2Colors.progressTrack)
                    .frame(height: 3)

                RoundedRectangle(cornerRadius: 2)
                    .fill(NCE2Colors.progressFill)
                    .frame(width: max(0, min(geometry.size.width * progress, geometry.size.width)), height: 3)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 3)
    }
}

// MARK: - Speed Chip

/// A tappable chip for playback speed selection.
struct SpeedChip: View {
    let speed: Float
    let isActive: Bool
    let action: () -> Void

    private var label: String {
        String(format: "%.2fx", speed)
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(.caption, design: .monospaced).bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isActive ? NCE2Colors.speedChipActive : NCE2Colors.speedChipInactive)
                )
                .foregroundColor(isActive ? .white : NCE2Colors.text)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - NCE2 Divider

/// A styled horizontal divider line.
struct NCE2Divider: View {
    var body: some View {
        Rectangle()
            .fill(NCE2Colors.separator)
            .frame(height: 1)
    }
}

// MARK: - Playback Time Labels

/// Displays current time and total duration in mono digits.
struct TimeLabels: View {
    let current: TimeInterval
    let total: TimeInterval

    var body: some View {
        HStack {
            Text(formatTime(current))
                .nce2MonoDigit()
            Spacer()
            Text(formatTime(total))
                .nce2MonoDigit()
        }
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        guard interval.isFinite && interval >= 0 else { return "00:00" }
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Sleep Timer Badge

/// Displays remaining sleep timer countdown.
struct SleepTimerBadge: View {
    let remaining: TimeInterval
    let onTap: () -> Void

    var body: some View {
        if remaining > 0 {
            Button(action: onTap) {
                HStack(spacing: 4) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 12))
                    Text(formatRemaining(remaining))
                        .font(.system(.caption, design: .monospaced).bold())
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(NCE2Colors.sleepTimerActive.opacity(0.15))
                )
                .foregroundColor(NCE2Colors.sleepTimerActive)
            }
            .buttonStyle(.plain)
        }
    }

    private func formatRemaining(_ interval: TimeInterval) -> String {
        let mins = Int(interval) / 60
        if mins >= 60 {
            let hours = mins / 60
            let remainingMins = mins % 60
            return "\(hours)h \(remainingMins)m"
        }
        return "\(mins)m"
    }
}

// MARK: - Import Status Icon

/// Shows cloud icon for unimported lessons.
struct ImportStatusIcon: View {
    let isImported: Bool

    var body: some View {
        if isImported {
            EmptyView()
        } else {
            HStack(spacing: 2) {
                Image(systemName: "icloud.and.arrow.down")
                    .font(.system(size: 11))
                Text("需导入")
                    .font(.system(size: 11))
            }
            .foregroundColor(NCE2Colors.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview("FavoriteStarButton") {
    VStack(spacing: 20) {
        FavoriteStarButton(isFavorite: false) {}
        FavoriteStarButton(isFavorite: true) {}
    }
    .padding()
    .background(NCE2Colors.background)
}

#Preview("LessonProgressBar") {
    VStack(spacing: 20) {
        LessonProgressBar(progress: 0.0)
        LessonProgressBar(progress: 0.45)
        LessonProgressBar(progress: 1.0)
    }
    .padding()
    .frame(width: 300)
    .background(NCE2Colors.background)
}

#Preview("SpeedChip") {
    HStack(spacing: 8) {
        SpeedChip(speed: 0.75, isActive: false) {}
        SpeedChip(speed: 1.0, isActive: true) {}
        SpeedChip(speed: 1.25, isActive: false) {}
        SpeedChip(speed: 1.5, isActive: false) {}
    }
    .padding()
    .background(NCE2Colors.background)
}
