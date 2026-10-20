import SwiftUI

// 1. 定义 AppDelegate，在 Swift 中实现代理方法
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true   // 最后一个窗口关闭后，退出应用
    }
}

@main struct MyApp: App {
    // 2. 把 AppDelegate 接入 SwiftUI 生命周期
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var paths = AppPaths.shared
    
    var body: some Scene {
        WindowGroup("RSA-Sakura") {
            ContentView()
                .task {
                    paths.discover()
                }
        }
        .windowResizability(.contentSize)          // 窗口尺寸由内容决定
        .defaultSize(width: 421, height: 218)      // 默认打开尺寸
    }
}
