//
//  NCE2EliteApp.swift
//  NCE2Elite
//
//  App entry point. Configures audio session, SwiftData, and splash screen.
//

import SwiftUI
import SwiftData
import AVFoundation

@main
struct NCE2EliteApp: App {
    @State private var showSplash = true
    @AppStorage("displayMode") private var displayModeRaw: String = DisplayMode.system.rawValue

    /// Shared SwiftData model container for LessonProgress.
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            LessonProgress.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color(red: 0.01, green: 0.04, blue: 0.10)
                    .ignoresSafeArea()

                RootTabView()
                    .modelContainer(sharedModelContainer)
                    .preferredColorScheme(colorScheme)

                if showSplash {
                    SplashView {
                        showSplash = false
                    }
                    .transition(.opacity)
                }
            }
            .onAppear {
                configureAudioSession()
            }
        }
    }

    // MARK: - Display Mode

    private var displayMode: DisplayMode {
        DisplayMode(rawValue: displayModeRaw) ?? .system
    }

    private var colorScheme: ColorScheme? {
        switch displayMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    // MARK: - Audio Session Configuration

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("⚠️ Audio session configuration failed: \(error)")
        }

        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

            if type == .began {
                // Audio was interrupted (e.g. phone call)
            } else if type == .ended {
                if let optionsValue = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) {
                        try? AVAudioSession.sharedInstance().setActive(true)
                    }
                }
            }
        }
    }
}
