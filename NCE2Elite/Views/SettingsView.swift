/// SettingsView — 设置页
/// 字体、显示模式、内容导入、导入指南、隐私政策

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Display Mode

enum DisplayMode: String, CaseIterable {
    case system = "跟随系统"
    case light = "浅色模式"
    case dark = "深色模式"
}

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("lessonFontSize") private var lessonFontSize: Double = 16
    @AppStorage("displayMode") private var displayModeRaw: String = DisplayMode.system.rawValue

    let importService: ImportService

    @State private var showImporter: Bool = false
    @State private var importerMode: ImporterMode = .audio
    @State private var importResult: String?
    @State private var showImportResult: Bool = false
    @State private var showImportGuide: Bool = false
    @State private var showPrivacyPolicy: Bool = false

    private var displayMode: DisplayMode {
        DisplayMode(rawValue: displayModeRaw) ?? .system
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: 显示
                Section("显示") {
                    // 字体大小
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("课文字体大小")
                                .font(NCE2Typography.body())
                            Spacer()
                            Text("\(Int(lessonFontSize))pt")
                                .font(NCE2Typography.monoDigit())
                                .foregroundStyle(NCE2Colors.textSecondary)
                        }
                        Slider(value: $lessonFontSize, in: 13...24, step: 1)
                            .tint(NCE2Colors.oxfordBlue)

                        // 实时预览
                        Text("Preview 预览文字")
                            .font(NCE2Typography.body(size: lessonFontSize))
                            .foregroundStyle(NCE2Colors.text)
                            .padding(.top, 4)
                    }

                    // 显示模式
                    Picker("显示模式", selection: $displayModeRaw) {
                        ForEach(DisplayMode.allCases, id: \.rawValue) { mode in
                            Text(mode.rawValue).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // MARK: 内容导入
                Section("内容导入") {
                    Button {
                        importerMode = .audio
                        showImporter = true
                    } label: {
                        Label("导入音频 (MP3)", systemImage: "music.note.list")
                    }

                    Button {
                        importerMode = .text
                        showImporter = true
                    } label: {
                        Label("导入课文文本 (JSON)", systemImage: "doc.text")
                    }

                    Button {
                        showImportGuide = true
                    } label: {
                        Label("导入指南", systemImage: "questionmark.circle")
                    }
                }

                // MARK: 导入状态
                Section("导入状态") {
                    HStack {
                        Text("已导入音频")
                        Spacer()
                        Text("\(importService.importedLessonIDs().count) / 96 课")
                            .foregroundStyle(NCE2Colors.textSecondary)
                    }
                }

                // MARK: 法律与隐私
                Section("法律与隐私") {
                    Button {
                        showPrivacyPolicy = true
                    } label: {
                        Label("隐私政策", systemImage: "hand.raised")
                    }

                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(NCE2Colors.textSecondary)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: importerMode == .audio
                    ? [.mp3] : [.json],
                allowsMultipleSelection: true
            ) { result in
                handleImport(result)
            }
            .sheet(isPresented: $showImportGuide) {
                ImportGuideView()
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .alert("导入结果", isPresented: $showImportResult) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(importResult ?? "")
            }
        }
        .preferredColorScheme(colorScheme)
    }

    private var colorScheme: ColorScheme? {
        switch displayMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    // MARK: - Import

    private enum ImporterMode {
        case audio, text
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            do {
                let count: Int
                if importerMode == .audio {
                    count = try importService.importAudioFiles(from: urls)
                } else {
                    count = try importService.importTextFiles(from: urls)
                }
                importResult = "成功导入 \(count) 个文件"
            } catch {
                importResult = "导入失败：\(error.localizedDescription)"
            }
        case .failure(let error):
            importResult = "导入失败：\(error.localizedDescription)"
        }
        showImportResult = true
    }
}

// MARK: - Import Guide View

struct ImportGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    GuideSection(
                        icon: "book.closed",
                        title: "获取正版内容",
                        content: """
                        您可以通过以下渠道获取《新概念英语》第二册的音频和文本：
                        • 购买正版教材配套 CD/MP3
                        • 朗文出版社官方或授权渠道
                        • 已购教材的配套数字资源
                        
                        ⚠️ 请仅导入您合法拥有的内容。
                        """
                    )

                    GuideSection(
                        icon: "music.note",
                        title: "音频格式要求",
                        content: """
                        音频文件要求：
                        • 格式：MP3（.mp3）
                        • 命名：Lesson01.mp3 ~ Lesson96.mp3
                           （两位数课号，如 Lesson01、Lesson15、Lesson96）
                        • 语言：英音发音
                        
                        可将全部 96 课音频放入一个文件夹后批量导入。
                        """
                    )

                    GuideSection(
                        icon: "doc.text",
                        title: "课文文本格式要求",
                        content: """
                        课文文本要求：
                        • 格式：JSON（.json）
                        • 命名：Lesson01.json ~ Lesson96.json
                        • 内容结构：
                        
                        {
                          "englishText": "英语课文内容...",
                          "chineseText": "中文翻译内容..."
                        }
                        
                        可将全部 96 课文本放入一个文件夹后批量导入。
                        """
                    )

                    GuideSection(
                        icon: "iphone.and.arrow.forward",
                        title: "如何导入",
                        content: """
                        1. 将音频/文本文件保存到您的设备
                        2. 打开本 App，进入「设置」→「内容导入」
                        3. 选择「导入音频」或「导入课文文本」
                        4. 在文件选择器中选中文件，点击「打开」
                        5. 导入成功后即可在课程列表中使用
                        
                        您也可以通过 AirDrop、iCloud Drive 等方式传输文件。
                        """
                    )

                    GuideSection(
                        icon: "exclamationmark.shield",
                        title: "版权声明",
                        content: """
                        本 App 作为学习框架工具分发，不包含任何版权内容。
                        
                        内置的试听预览课程（Lesson 01–02）属于合理使用范畴，仅用于功能演示。
                        
                        用户需自行导入合法获取的学习材料。本 App 开发者不提供、不存储、不分发任何受版权保护的教材内容。
                        
                        如有版权问题，请联系版权方。
                        """
                    )
                }
                .padding(20)
            }
            .background(NCE2Colors.background)
            .navigationTitle("导入指南")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

struct GuideSection: View {
    let icon: String
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(NCE2Colors.oxfordBlue)
                    .frame(width: 28)

                Text(title)
                    .font(NCE2Typography.lessonTitle())
                    .foregroundStyle(NCE2Colors.text)
            }

            Text(content)
                .font(NCE2Typography.body())
                .foregroundStyle(NCE2Colors.textSecondary)
                .lineSpacing(4)
                .padding(.leading, 36)
        }
        .padding(16)
        .background(NCE2Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Privacy Policy View

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    privacySection(
                        title: "Privacy Policy / 隐私政策",
                        content: """
                        Last updated: 2026-07-25
                        最后更新：2026年7月25日

                        NCE2 Elite ("the App") is committed to protecting your privacy. This privacy policy explains how we handle your data.
                        
                        NCE2 Elite（"本应用"）致力于保护您的隐私。本隐私政策说明我们如何处理您的数据。
                        """
                    )

                    privacySection(
                        title: "Data Collection / 数据收集",
                        content: """
                        The App does not collect, transmit, or share any personal information. All data is stored locally on your device.
                        
                        The following data is stored locally:
                        • Playback progress per lesson
                        • Favorite lesson bookmarks
                        • App preferences (font size, display mode, etc.)
                        
                        本应用不收集、传输或分享任何个人信息。所有数据均存储在您的设备本地。
                        
                        以下数据存储在本地：
                        • 每课的播放进度
                        • 收藏课程书签
                        • 应用偏好设置（字体大小、显示模式等）
                        """
                    )

                    privacySection(
                        title: "Data Usage / 数据使用",
                        content: """
                        All locally stored data is used solely for providing the App's core functionality (resuming playback, favorites, personalization). This data never leaves your device.
                        
                        所有本地存储的数据仅用于提供应用核心功能（续播、收藏、个性化设置）。这些数据不会离开您的设备。
                        """
                    )

                    privacySection(
                        title: "Third-Party Services / 第三方服务",
                        content: """
                        The App does not integrate any third-party analytics, advertising, or tracking services. It uses only Apple system frameworks.
                        
                        本应用不集成任何第三方分析、广告或追踪服务。仅使用 Apple 系统框架。
                        """
                    )

                    privacySection(
                        title: "Audio Files & Copyright / 音频文件与版权",
                        content: """
                        The App does not include copyrighted audio content. Built-in preview lessons are for demonstration purposes only. Users must import legally acquired learning materials.
                        
                        本应用不包含版权音频内容。内置试听课程仅供功能演示。用户需导入合法获取的学习材料。
                        """
                    )

                    privacySection(
                        title: "Contact / 联系方式",
                        content: """
                        If you have any questions about this privacy policy, please contact us at:
                        如对本隐私政策有任何疑问，请联系：
                        
                        [Your Contact Email]
                        """
                    )
                }
                .padding(20)
            }
            .background(NCE2Colors.background)
            .navigationTitle("隐私政策")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func privacySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(NCE2Typography.lessonTitle())
                .foregroundStyle(NCE2Colors.text)

            Text(content)
                .font(NCE2Typography.body())
                .foregroundStyle(NCE2Colors.textSecondary)
                .lineSpacing(4)
        }
        .padding(16)
        .background(NCE2Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
