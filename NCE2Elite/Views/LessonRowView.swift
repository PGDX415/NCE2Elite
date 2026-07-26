//
//  LessonRowView.swift
//  NCE2Elite
//
//  Card-style row for a single lesson in the list.
//

import SwiftUI

struct LessonRowView: View {
    let lesson: Lesson
    let isFavorite: Bool
    let isAudioAvailable: Bool
    let progress: Double
    let onToggleFavorite: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Lesson number badge
                    lessonNumberBadge

                    // Title and metadata
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lesson.title)
                            .nce2LessonTitle()
                            .lineLimit(2)

                        HStack(spacing: 8) {
                            ImportStatusIcon(isImported: isAudioAvailable)

                            if lesson.durationSeconds > 0 {
                                Text(formatDuration(lesson.durationSeconds))
                                    .nce2Caption()
                            }
                        }
                    }

                    Spacer()

                    // Favorite star
                    FavoriteStarButton(isFavorite: isFavorite) {
                        onToggleFavorite()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // Progress bar
                if progress > 0 {
                    LessonProgressBar(progress: progress)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
            }
            .background(NCE2Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Lesson Number Badge

    private var lessonNumberBadge: some View {
        ZStack {
            Circle()
                .fill(
                    lesson.id % 3 == 0 ? NCE2Colors.antiqueGold.opacity(0.2) :
                    lesson.id % 3 == 1 ? NCE2Colors.oxfordBlue.opacity(0.15) :
                    NCE2Colors.bordeaux.opacity(0.12)
                )
                .frame(width: 40, height: 40)

            Text("\(lesson.lessonNumber)")
                .font(.system(.callout, design: .monospaced).bold())
                .foregroundColor(
                    lesson.id % 3 == 0 ? NCE2Colors.antiqueGold :
                    lesson.id % 3 == 1 ? NCE2Colors.oxfordBlue :
                    NCE2Colors.bordeaux
                )
        }
    }

    // MARK: - Helpers

    private func formatDuration(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 8) {
        LessonRowView(
            lesson: Lesson.preview,
            isFavorite: true,
            isAudioAvailable: true,
            progress: 0.45,
            onToggleFavorite: {},
            onTap: {}
        )
        LessonRowView(
            lesson: Lesson(id: 3, lessonNumber: 3, title: "Please Send Me a Card", audioFileName: "Lesson03", durationSeconds: 0),
            isFavorite: false,
            isAudioAvailable: false,
            progress: 0,
            onToggleFavorite: {},
            onTap: {}
        )
    }
    .padding()
    .background(NCE2Colors.background)
}
