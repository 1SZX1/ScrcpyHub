import SwiftUI
import AppKit

public struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject private var langManager = LanguageManager.shared
    @ObservedObject private var adbService = ADBService.shared
    @ObservedObject private var processManager = ProcessManager.shared
    
    public init() {}
    
    public var body: some View {
        // 在线设备列表与快速启停
        if adbService.devices.isEmpty {
            Text(t("menubar_no_devices"))
        } else {
            Section("\(t("menubar_online_devices")) (\(adbService.devices.count))") {
                ForEach(adbService.devices) { dev in
                    Button {
                        if dev.isMirroring {
                            processManager.stopMirroring(serial: dev.serial)
                        } else {
                            processManager.startMirroring(device: dev, config: ScrcpyConfig.loadDefault())
                        }
                    } label: {
                        if dev.isMirroring {
                            Label("\(t("menubar_stop_mirror"))\(dev.displayName)", systemImage: "stop.circle.fill")
                        } else {
                            Label("\(t("menubar_start_mirror"))\(dev.displayName)", systemImage: "play.circle.fill")
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
            Label(t("menubar_open_console"), systemImage: "macwindow")
        }
        .keyboardShortcut("o", modifiers: [.command])
        
        Button {
            adbService.refreshDevices(isManual: true)
        } label: {
            Label(t("menubar_refresh"), systemImage: "arrow.clockwise")
        }
        .keyboardShortcut("r", modifiers: [.command])
        
        Divider()
        
        // 界面语言快速切换
        Menu {
            ForEach(AppLanguage.allCases) { lang in
                Button {
                    langManager.selectedLanguage = lang
                } label: {
                    HStack {
                        Text(lang.displayName)
                        if langManager.selectedLanguage == lang {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Label(t("menubar_language"), systemImage: "globe")
        }
        
        Divider()
        
        // 退出选项
        Button {
            processManager.stopAll()
            NSApplication.shared.terminate(nil)
        } label: {
            Label(t("menubar_quit"), systemImage: "power")
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
