import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        ProcessManager.shared.stopAll()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // 允许关闭主窗口后仍然常驻在菜单栏
        return false
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            if let window = sender.windows.first(where: { !($0 is NSPanel) && $0.canBecomeMain }) {
                window.makeKeyAndOrderFront(nil)
            }
        }
        return true
    }
}

@main
struct ScrcpyHubApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow
    
    var body: some Scene {
        // 主工作台窗口 (使用单例 Window 替代 WindowGroup，避免重复多开窗口)
        Window(t("app_title"), id: "main") {
            MainView()
                .frame(minWidth: 880, minHeight: 620)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 960, height: 680)
        
        // 顶部系统状态栏常驻图标 (双模态 - 原生系统菜单)
        MenuBarExtra("ScrcpyHub", systemImage: "display.and.arrow.down") {
            MenuBarView()
        }
        .menuBarExtraStyle(.menu)
    }
}
