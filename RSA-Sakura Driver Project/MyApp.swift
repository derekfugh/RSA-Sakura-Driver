import SwiftUI

@main struct MyApp: App {
    @StateObject private var paths = AppPaths.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    paths.discover()
                }
        }
        .windowResizability(.contentSize)          // 窗口尺寸由内容决定
        .defaultSize(width: 421, height: 218)      // 默认打开尺寸
    }
}
