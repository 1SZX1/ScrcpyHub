import SwiftUI
import AppKit

public struct FloatingToolbarView: View {
    public let device: Device
    @State private var toastMessage: String? = nil
    @State private var isShowingToast: Bool = false
    @State private var isDropTargeted: Bool = false
    
    public var body: some View {
        VStack(spacing: 8) {
            // 顶部抓手与设备微型状态 (可拖动区域)
            ZStack {
                WindowDragHandleView()
                
                HStack {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    Text(device.displayName)
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let battery = device.batteryLevel {
                        HStack(spacing: 2) {
                            Image(systemName: device.isCharging == true ? "bolt.fill" : "battery.75")
                                .font(.system(size: 9))
                                .foregroundColor(device.isCharging == true ? .green : .secondary)
                            Text("\(battery)%")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        FloatingToolbarWindowManager.shared.closeToolbar(for: device.serial)
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 6)
            
            Divider().opacity(0.3)
            
            // 实体按键区
            HStack(spacing: 12) {
                // 返回
                ToolbarIconButton(icon: "chevron.backward", tooltip: "返回 (Back)") {
                    ADBService.shared.sendKeyevent(serial: device.serial, keycode: 4)
                }
                
                // 主页
                ToolbarIconButton(icon: "circle.circle", tooltip: "主屏幕 (Home)") {
                    ADBService.shared.sendKeyevent(serial: device.serial, keycode: 3)
                }
                
                // 多任务
                ToolbarIconButton(icon: "square.stack.3d.up", tooltip: "最近任务 (Recents)") {
                    ADBService.shared.sendKeyevent(serial: device.serial, keycode: 187)
                }
                
                // 音量减
                ToolbarIconButton(icon: "speaker.minus", tooltip: "音量 -") {
                    ADBService.shared.sendKeyevent(serial: device.serial, keycode: 25)
                }
                
                // 音量加
                ToolbarIconButton(icon: "speaker.plus", tooltip: "音量 +") {
                    ADBService.shared.sendKeyevent(serial: device.serial, keycode: 24)
                }
                
                // 电源 / 息屏唤醒
                ToolbarIconButton(icon: "power", tooltip: "电源键 / 点亮息屏") {
                    ADBService.shared.sendKeyevent(serial: device.serial, keycode: 26)
                }
                
                // 通知栏
                ToolbarIconButton(icon: "bell", tooltip: "下拉通知栏") {
                    ADBService.shared.expandNotifications(serial: device.serial)
                }
                
                // 截屏
                ToolbarIconButton(icon: "camera", tooltip: "屏幕截图 (存至下载目录)") {
                    triggerScreenshot()
                }
            }
            .padding(.horizontal, 10)
            
            // 快捷拖拽安装/传输提示条
            HStack(spacing: 4) {
                Image(systemName: "arrow.down.doc")
                    .font(.system(size: 10))
                Text("拖入 APK 安装或文件直传")
                    .font(.system(size: 10))
            }
            .foregroundColor(.secondary)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(isDropTargeted ? Color.accentColor.opacity(0.2) : Color.primary.opacity(0.04))
            .cornerRadius(6)
            .padding(.horizontal, 8)
            .padding(.bottom, 6)
            .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                handleDroppedFiles(providers: providers)
                return true
            }
            
            // Toast 提示
            if let toast = toastMessage {
                Text(toast)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(4)
                    .transition(.opacity)
                    .padding(.bottom, 4)
            }
        }
        .frame(width: 320)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    private func triggerScreenshot() {
        showToast("正在截屏...")
        Task {
            let res = await ADBService.shared.takeScreenshot(serial: device.serial)
            await MainActor.run {
                switch res {
                case .success(let url):
                    showToast("截屏已保存: \(url.lastPathComponent)")
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                case .failure(let err):
                    showToast("截屏失败: \(err.localizedDescription)")
                }
            }
        }
    }
    
    private func handleDroppedFiles(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                
                Task { @MainActor in
                    if url.pathExtension.lowercased() == "apk" {
                        self.showToast("正在安装 APK: \(url.lastPathComponent)...")
                        let res = await ADBService.shared.installApk(serial: self.device.serial, fileUrl: url)
                        switch res {
                        case .success(let msg): self.showToast(msg)
                        case .failure(let err): self.showToast("安装失败: \(err.localizedDescription)")
                        }
                    } else {
                        self.showToast("正在传输文件: \(url.lastPathComponent)...")
                        let res = await ADBService.shared.pushFile(serial: self.device.serial, fileUrl: url)
                        switch res {
                        case .success(let msg): self.showToast(msg)
                        case .failure(let err): self.showToast("传输失败: \(err.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    private func showToast(_ text: String) {
        toastMessage = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if self.toastMessage == text {
                self.toastMessage = nil
            }
        }
    }
}

struct ToolbarIconButton: View {
    let icon: String
    let tooltip: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .frame(width: 24, height: 24)
                .background(isHovered ? Color.primary.opacity(0.12) : Color.primary.opacity(0.05))
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { isHovered = $0 }
    }
}

public struct VisualEffectView: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode
    
    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

final class WindowDragHandleNSView: NSView {
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}

struct WindowDragHandleView: NSViewRepresentable {
    init() {}
    func makeNSView(context: Context) -> WindowDragHandleNSView {
        WindowDragHandleNSView()
    }
    func updateNSView(_ nsView: WindowDragHandleNSView, context: Context) {}
}
