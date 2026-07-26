/// SplashView — 启动画面（渐隐过渡）

import SwiftUI

struct SplashView: View {
    @State private var opacity: Double = 1.0
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            NCE2Colors.oxfordBlue
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // App Icon Area
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(NCE2Colors.antiqueGold.opacity(0.15))
                        .frame(width: 90, height: 90)

                    VStack(spacing: 4) {
                        Image(systemName: "book.pages.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(NCE2Colors.antiqueGold)
                        Image(systemName: "waveform")
                            .font(.system(size: 16))
                            .foregroundStyle(NCE2Colors.antiqueGold.opacity(0.7))
                    }
                }

                Text("NCE2 Elite")
                    .font(NCE2Typography.brandTitle())
                    .foregroundStyle(NCE2Colors.antiqueGold)

                Text("新概念英语 · 第二册")
                    .font(NCE2Typography.body())
                    .foregroundStyle(Color.white.opacity(0.6))

                Text("Practice and Progress 🇬🇧")
                    .font(NCE2Typography.caption())
                    .foregroundStyle(Color.white.opacity(0.4))
                    .padding(.top, 4)
            }
        }
        .opacity(opacity)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.6)) {
                    opacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    onDismiss()
                }
            }
        }
    }
}
