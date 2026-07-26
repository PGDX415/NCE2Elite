/// NCE2EliteApp — @main 入口
/// 音频会话配置 + 中断处理

import SwiftUI
import SwiftData
import AVFoundation

@main
struct NCE2EliteApp: App {
    @AppStorage("displayMode") private var displayModeRaw: String = DisplayMode.system.rawValue

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([LessonProgress.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .modelContainer(sharedModelContainer)
                .onAppear {
                    configureAudioSession()
                }
                .preferredColorScheme(colorScheme)
        }
    }

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

    /// 配置音频会话：支持后台播放、中断处理
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("⚠️ Audio session configuration failed: \(error)")
        }

        // 注册音频中断通知
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
