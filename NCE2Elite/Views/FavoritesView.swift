//
//  FavoritesView.swift
//  NCE2Elite
//
//  Favorites tab showing bookmarked lessons.
//

import SwiftUI

struct FavoritesView: View {
    let viewModel: FavoritesViewModel
    let listViewModel: LessonListViewModel
    let onPlayLesson: (Lesson) -> Void

    @State private var showImportAlert = false
    @State private var selectedLesson: Lesson?

    var body: some View {
        Group {
            if viewModel.favoriteLessons.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "star.slash")
                        .font(.system(size: 48))
                        .foregroundColor(NCE2Colors.antiqueGold.opacity(0.5))
                    Text("暂无收藏课程")
                        .font(.system(.headline, design: .serif))
                        .foregroundColor(NCE2Colors.textSecondary)
                    Text("在课程列表中点击星标\n即可收藏喜欢的课程")
                        .font(.system(.body, design: .serif))
                        .foregroundColor(NCE2Colors.textSecondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(NCE2Colors.background)
            } else {
                List {
                    ForEach(viewModel.favoriteLessons) { lesson in
                        LessonRowView(
                            lesson: lesson,
                            isFavorite: true,
                            isAudioAvailable: viewModel.isAudioAvailable(for: lesson),
                            progress: viewModel.progress(for: lesson.id),
                            onToggleFavorite: {
                                viewModel.toggleFavorite(for: lesson.id)
                                listViewModel.refreshFavorites()
                            },
                            onTap: {
                                handleLessonTap(lesson)
                            }
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(NCE2Colors.background)
            }
        }
        .alert("内容未导入", isPresented: $showImportAlert) {
            Button("去设置导入") {}
            Button("取消", role: .cancel) {}
        } message: {
            if let lesson = selectedLesson {
                Text("Lesson \(String(format: "%02d", lesson.lessonNumber))「\(lesson.title)」的音频尚未导入。")
            }
        }
    }

    private func handleLessonTap(_ lesson: Lesson) {
        if viewModel.isAudioAvailable(for: lesson) {
            onPlayLesson(lesson)
        } else {
            selectedLesson = lesson
            showImportAlert = true
        }
    }
}
