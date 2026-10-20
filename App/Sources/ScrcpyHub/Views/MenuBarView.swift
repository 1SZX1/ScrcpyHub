import SwiftUI
import AppKit

public struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject private var adbService = ADBService.shared
    @ObservedObject private var processManager = ProcessManager.shared
    
    public init() {}
    
    public var body: some View {
        // 在线设备列表与快速启停
        if adbService.devices.isEmpty {
            Text("未检测到 Android 设备")
        } else {
            Section("在线设备 (\(adbService.devices.count))") {
                ForEach(adbService.devices) { dev in
                    Button {
                        if dev.isMirroring {
                            processManager.stopMirroring(serial: dev.serial)
                        } else {
                            processManager.startMirroring(device: dev, config: ScrcpyConfig.loadDefault())
                        }
                    } label: {
                        if dev.isMirroring {
                            Label("停止投屏: \(dev.displayName)", systemImage: "stop.circle.fill")
                        } else {
                            Label("启动投屏: \(dev.displayName)", systemImage: "play.circle.fill")
                        }
                    }
                    .disabled(!dev.state.isUsable)
                }
            }
        }
        
        Divider()
        
        // 核心控制项
        Button {
            openMainWindow()
        } label: {
            Label("打开主控制面板", systemImage: "macwindow")
        }
        .keyboardShortcut("o", modifiers: [.command])
        
        Button {
            adbService.refreshDevices(isManual: true)
        } label: {
            Label("刷新设备列表", systemImage: "arrow.clockwise")
        }
        .keyboardShortcut("r", modifiers: [.command])
        
        Divider()
        
        // 退出选项
        Button {
            processManager.stopAll()
            NSApplication.shared.terminate(nil)
        } label: {
            Label("退出 ScrcpyHub", systemImage: "power")
        }
        .keyboardShortcut("q", modifiers: [.command])
    }
    
    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { !($0 is NSPanel) && $0.canBecomeMain }) {
            if window.isMiniaturized {
                window.deminiaturize(nil)
            }
            window.makeKeyAndOrderFront(nil)
        } else {
            openWindow(id: "main")
        }
    }
}
