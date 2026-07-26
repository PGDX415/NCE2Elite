//
//  LessonListView.swift
//  NCE2Elite
//
//  Main lesson list with search, quick-jump bar, and import intercept alert.
//  Displays all 96 lessons in a flat list sorted by lesson number.
//

import SwiftUI

/// The main lesson list screen (home tab).
struct LessonListView: View {
    let viewModel: LessonListViewModel
    let onPlayLesson: (Lesson) -> Void

    @State private var showImportAlert = false
    @State private var selectedLesson: Lesson?

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            searchBar

            // Lesson list
            ScrollViewReader { proxy in
                List {
                    ForEach(viewModel.filteredLessons) { lesson in
                        LessonRowView(
                            lesson: lesson,
                            isFavorite: viewModel.isFavorite(lesson.id),
                            isAudioAvailable: viewModel.isAudioAvailable(for: lesson),
                            progress: viewModel.progress(for: lesson.id),
                            onToggleFavorite: {
                                viewModel.toggleFavorite(for: lesson.id)
                            },
                            onTap: {
                                handleLessonTap(lesson)
                            }
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .id(lesson.id)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(NCE2Colors.background)

                // Quick-jump bar
                quickJumpBar(proxy: proxy)
            }
        }
        .background(NCE2Colors.background)
        .alert("内容未导入", isPresented: $showImportAlert) {
            Button("去设置导入") {}
            Button("取消", role: .cancel) {}
        } message: {
            if let lesson = selectedLesson {
                Text("Lesson \(String(format: "%02d", lesson.lessonNumber))「\(lesson.title)」的音频尚未导入。\n请前往设置页面导入音频文件。")
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(NCE2Colors.textSecondary)

            TextField("搜索课号或标题...", text: Binding(
                get: { viewModel.searchText },
                set: { viewModel.searchText = $0 }
            ))
            .font(.system(.body, design: .serif))
            .foregroundColor(NCE2Colors.text)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(NCE2Colors.textSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(NCE2Colors.card)
    }

    // MARK: - Quick Jump Bar

    private func quickJumpBar(proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 8) {
            ForEach(viewModel.jumpAnchors, id: \.self) { anchor in
                Button {
                    withAnimation {
                        proxy.scrollTo(anchor, anchor: .top)
                    }
                } label: {
                    Text("\(anchor)")
                        .font(.system(.caption, design: .monospaced).bold())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(NCE2Colors.separator.opacity(0.5))
                        )
                        .foregroundColor(NCE2Colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(NCE2Colors.background)
    }

    // MARK: - Actions

    private func handleLessonTap(_ lesson: Lesson) {
        if viewModel.isAudioAvailable(for: lesson) {
            onPlayLesson(lesson)
        } else {
            selectedLesson = lesson
            showImportAlert = true
        }
    }
}

// MARK: - Preview

#Preview {
    let dataService = LessonDataService()
    let importService = ImportService()
    let vm = LessonListViewModel(lessonDataService: dataService, importService: importService)

    LessonListView(viewModel: vm, onPlayLesson: { _ in })
}
