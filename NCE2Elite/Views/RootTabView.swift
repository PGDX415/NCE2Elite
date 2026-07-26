//
//  RootTabView.swift
//  NCE2Elite
//
//  Main tab bar layout with adaptive iPhone/iPad support.
//  Manages app-wide color scheme, settings sheet, and player navigation.
//

import SwiftUI
import SwiftData

/// The root view of the app containing the tab bar and global state management.
struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext

    // MARK: - App Storage

    @AppStorage("colorSchemeMode") private var colorSchemeMode: String = "system"

    // MARK: - Services

    @State private var lessonDataService = LessonDataService()
    @State private var importService = ImportService()
    @State private var audioService = AudioPlayerService()

    // MARK: - ViewModels

    @State private var lessonListVM: LessonListViewModel?
    @State private var favoritesVM: FavoritesViewModel?
    @State private var playerVM: PlayerViewModel?

    // MARK: - State

    @State private var showSettings = false
    @State private var selectedTab = 0

    /// Trigger for fullScreenCover. A new UUID forces SwiftUI to
    /// re-create the presentation each time.
    @State private var playerPresentationID: PlayerPresentation?

    // MARK: - Color Scheme

    private var preferredColorScheme: ColorScheme? {
        switch colorSchemeMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            if let lessonListVM, let favoritesVM, let playerVM {
                TabView(selection: $selectedTab) {
                    // Lessons tab
                    NavigationStack {
                        LessonListView(
                            viewModel: lessonListVM,
                            onPlayLesson: { lesson in
                                playerVM.play(lesson: lesson)
                                playerPresentationID = PlayerPresentation()
                            }
                        )
                        .navigationTitle("NCE2 Elite")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                VStack(spacing: 2) {
                                    HStack(spacing: 6) {
                                        // Union Jack mini accent
                                        HStack(spacing: 1.5) {
                                            Rectangle().fill(NCE2Colors.bordeaux).frame(width: 3, height: 14)
                                            Rectangle().fill(NCE2Colors.textSecondary.opacity(0.3)).frame(width: 3, height: 14)
                                            Rectangle().fill(NCE2Colors.oxfordBlue).frame(width: 3, height: 14)
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: 1.5))

                                        Text("新概念英语第二册")
                                            .font(.system(size: 20, design: .serif).weight(.bold))
                                            .foregroundColor(NCE2Colors.oxfordBlue)
                                    }
                                    Text("🇬🇧 有声伴读 · NCE2 Elite")
                                        .font(.system(size: 11, design: .default).monospacedDigit())
                                        .foregroundColor(NCE2Colors.textSecondary)
                                }
                            }
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    showSettings = true
                                } label: {
                                    Image(systemName: "gearshape")
                                        .foregroundColor(NCE2Colors.oxfordBlue)
                                }
                            }
                        }
                    }
                    .tabItem {
                        Image(systemName: "book.pages")
                        Text("课程")
                    }
                    .tag(0)

                    // Favorites tab
                    NavigationStack {
                        FavoritesView(
                            viewModel: favoritesVM,
                            listViewModel: lessonListVM,
                            onPlayLesson: { lesson in
                                playerVM.play(lesson: lesson)
                                playerPresentationID = PlayerPresentation()
                            }
                        )
                        .navigationTitle("收藏")
                        .navigationBarTitleDisplayMode(.large)
                    }
                    .tabItem {
                        Image(systemName: "star")
                        Text("收藏")
                    }
                    .tag(1)
                }
                .tint(NCE2Colors.oxfordBlue)
                .sheet(isPresented: $showSettings) {
                    SettingsView(importService: importService)
                }
                .fullScreenCover(item: $playerPresentationID) { _ in
                    NavigationStack {
                        PlayerView(viewModel: playerVM)
                    }
                }
                .onAppear {
                    lessonListVM.refreshFavorites()
                }
            }
        }
        .preferredColorScheme(preferredColorScheme)
        .onAppear {
            setupViewModels()
        }
    }

    // MARK: - Setup

    private func setupViewModels() {
        let listVM = LessonListViewModel(lessonDataService: lessonDataService, importService: importService)
        listVM.setModelContext(modelContext)

        let favVM = FavoritesViewModel(lessonDataService: lessonDataService, importService: importService)
        favVM.setModelContext(modelContext)

        let playVM = PlayerViewModel(
            audioService: audioService,
            importService: importService,
            lessonDataService: lessonDataService
        )
        playVM.setModelContext(modelContext)

        self.lessonListVM = listVM
        self.favoritesVM = favVM
        self.playerVM = playVM

        Task { await importService.preloadAllDurations() }
    }
}

// MARK: - PlayerPresentation (Identifiable Wrapper)

struct PlayerPresentation: Identifiable {
    let id = UUID()
}

#Preview {
    RootTabView()
        .modelContainer(for: LessonProgress.self)
}
