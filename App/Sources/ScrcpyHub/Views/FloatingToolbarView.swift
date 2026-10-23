import SwiftUI
import AppKit

public struct FloatingToolbarView: View {
    @ObservedObject private var langManager = LanguageManager.shared
    public let device: Device
    @State private var toastMessage: String? = nil
    @State private var isShowingToast: Bool = false
    @State private var isDropTargeted: Bool = false
    
    struct TransferState: Equatable {
        var fileName: String
        var currentIndex: Int
        var totalCount: Int
        var progress: Double?
        var isApk: Bool
    }
    
    @State private var currentTransfer: TransferState? = nil
    @State private var activeTransferProcess: Process? = nil
    @State private var isTransferCancelled: Bool = false
    @State private var transferTask: Task<Void, Never>? = nil
    
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
                    .help(t("close_dock"))
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 6)
            
            Divider().opacity(0.3)
            
            // 实体按键区
            HStack(spacing: 12) {
                // 返回
                ToolbarIconButton(icon: "chevron.backward", tooltip: t("key_back")) {
                    ADBService.shared.sendKeyevent(serial: device.serial, keycode: 4)
                }
                
                // 主页
                ToolbarIconButton(icon: "circle.circle", tooltip: t("key_home")) {
                    ADBService.shared.sendKeyevent(serial: device.serial, keycode: 3)
                }
                
                // 多任务
                ToolbarIconButton(icon: "square.stack.3d.up", tooltip: t("key_recents")) {
                    ADBService.shared.sendKeyevent(serial: device.serial, keycode: 187)
                }
                
                // 音量减
                ToolbarIconButton(icon: "speaker.minus", tooltip: t("key_vol_down")) {
                    ADBService.shared.sendKeyevent(serial: device.serial, keycode: 25)
                }
                
                // 音量加
                ToolbarIconButton(icon: "speaker.plus", tooltip: t("key_vol_up")) {
                    ADBService.shared.sendKeyevent(serial: device.serial, keycode: 24)
                }
                
                // 电源 / 息屏唤醒
                ToolbarIconButton(icon: "power", tooltip: t("key_power")) {
                    ADBService.shared.sendKeyevent(serial: device.serial, keycode: 26)
                }
                
                // 通知栏
                ToolbarIconButton(icon: "bell", tooltip: t("key_notifications")) {
                    ADBService.shared.expandNotifications(serial: device.serial)
                }
                
                // 截屏
                ToolbarIconButton(icon: "camera", tooltip: t("key_screenshot")) {
                    triggerScreenshot()
                }
            }
            .padding(.horizontal, 10)
            
            // 快捷拖拽安装/传输提示条 或 实时进度条
            if let transfer = currentTransfer {
                HStack(spacing: 8) {
                    Image(systemName: transfer.isApk ? "arrow.down.app.fill" : "doc.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            let label = transfer.totalCount > 1
                                ? "[\(transfer.currentIndex)/\(transfer.totalCount)] \(transfer.fileName)"
                                : transfer.fileName
                            Text(label)
                                .font(.system(size: 10, weight: .medium))
                                .lineLimit(1)
                                .truncationMode(.middle)
                            
                            Spacer()
                            
                            if let p = transfer.progress {
                                Text("\(Int(p * 100))%")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.secondary)
                            } else {
                                Text(t("installing_apk"))
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let p = transfer.progress {
                            ProgressView(value: p, total: 1.0)
                                .progressViewStyle(.linear)
                                .controlSize(.mini)
                                .animation(.linear(duration: 0.15), value: p)
                        } else {
                            ProgressView()
                                .progressViewStyle(.linear)
                                .controlSize(.mini)
                        }
                    }
                    
                    Button(action: cancelCurrentTransfer) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(t("cancel_transfer"))
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity)
                .background(Color.primary.opacity(0.06))
                .cornerRadius(6)
                .padding(.horizontal, 8)
                .padding(.bottom, 6)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 10))
                    Text(t("drag_apk_file_hint"))
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
        showToast(langManager.isChinese ? "正在截屏..." : "Taking screenshot...")
        Task {
            let res = await ADBService.shared.takeScreenshot(serial: device.serial)
            await MainActor.run {
                switch res {
                case .success(let url):
                    showToast((langManager.isChinese ? "截屏已保存: " : "Saved: ") + url.lastPathComponent)
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                case .failure(let err):
                    showToast((langManager.isChinese ? "截屏失败: " : "Screenshot failed: ") + err.localizedDescription)
                }
            }
        }
    }
    
    private func handleDroppedFiles(providers: [NSItemProvider]) {
        let group = DispatchGroup()
        var loadedUrls: [URL] = []
        let lock = NSLock()
        
        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                defer { group.leave() }
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                lock.lock()
                loadedUrls.append(url)
                lock.unlock()
            }
        }
        
        group.notify(queue: .main) {
            guard !loadedUrls.isEmpty else { return }
            self.startTransferQueue(urls: loadedUrls)
        }
    }
    
    private func startTransferQueue(urls: [URL]) {
        transferTask?.cancel()
        isTransferCancelled = false
        
        transferTask = Task { @MainActor in
            let total = urls.count
            for (idx, url) in urls.enumerated() {
                if Task.isCancelled || isTransferCancelled { break }
                
                let isApk = url.pathExtension.lowercased() == "apk"
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentTransfer = TransferState(
                        fileName: url.lastPathComponent,
                        currentIndex: idx + 1,
                        totalCount: total,
                        progress: isApk ? nil : 0.0,
                        isApk: isApk
                    )
                }
                
                if isApk {
                    let res = await ADBService.shared.installApkWithProgress(
                        serial: device.serial,
                        fileUrl: url,
                        onProcessReady: { proc in
                            DispatchQueue.main.async { self.activeTransferProcess = proc }
                        }
                    )
                    guard !Task.isCancelled && !isTransferCancelled else { break }
                    switch res {
                    case .success(let msg): showToast(msg)
                    case .failure(let err): showToast(err.localizedDescription)
                    }
                } else {
                    let res = await ADBService.shared.pushFileWithProgress(
                        serial: device.serial,
                        fileUrl: url,
                        onProgress: { prog in
                            DispatchQueue.main.async {
                                if var cur = self.currentTransfer, !self.isTransferCancelled {
                                    cur.progress = prog
                                    self.currentTransfer = cur
                                }
                            }
                        },
                        onProcessReady: { proc in
                            DispatchQueue.main.async { self.activeTransferProcess = proc }
                        }
                    )
                    guard !Task.isCancelled && !isTransferCancelled else { break }
                    switch res {
                    case .success(let msg): showToast(msg)
                    case .failure(let err): showToast(err.localizedDescription)
                    }
                }
            }
            
            withAnimation(.easeInOut(duration: 0.25)) {
                self.currentTransfer = nil
                self.activeTransferProcess = nil
            }
        }
    }
    
    private func cancelCurrentTransfer() {
        isTransferCancelled = true
        transferTask?.cancel()
        activeTransferProcess?.terminate()
        activeTransferProcess = nil
        withAnimation(.easeInOut(duration: 0.2)) {
            currentTransfer = nil
        }
        showToast(t("transfer_cancelled"))
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
