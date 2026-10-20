import Foundation
import Combine

public struct RunningSession: Identifiable {
    public var id: String { serial }
    public let serial: String
    public let deviceName: String
    public let process: Process
    public let startedAt: Date
    public var logs: [String] = []
}

@MainActor
public final class ProcessManager: ObservableObject {
    public static let shared = ProcessManager()
    
    @Published public var activeSerials: Set<String> = []
    @Published public var sessionLogs: [String: [String]] = [:]
    @Published public var lastErrorMessage: String? = nil
    
    private var processes: [String: Process] = [:]
    
    private init() {}
    
    public func isRunning(serial: String) -> Bool {
        return activeSerials.contains(serial)
    }
    
    /// 为指定设备启动 scrcpy 投屏
    public func startMirroring(device: Device, config: ScrcpyConfig) {
        let serial = device.serial
        guard !isRunning(serial: serial) else { return }
        
        let scrcpyBin = BinaryLocator.shared.scrcpyPath()
        let adbBin = BinaryLocator.shared.adbPath()
        let serverPath = BinaryLocator.shared.scrcpyServerPath()
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: scrcpyBin)
        
        // 组装命令行参数
        let args = config.toArguments(serial: serial)
        process.arguments = args
        
        // 注入运行环境变量
        var env = ProcessInfo.processInfo.environment
        let binDir = URL(fileURLWithPath: adbBin).deletingLastPathComponent().path
        env["PATH"] = "\(binDir):/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:" + (env["PATH"] ?? "")
        env["ADB"] = adbBin
        if let serverPath = serverPath {
            env["SCRCPY_SERVER_PATH"] = serverPath
        }
        process.environment = env
        
        // 捕获日志输出
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        
        self.sessionLogs[serial] = ["[系统] 启动投屏命令: \(scrcpyBin) \(args.joined(separator: " "))"]
        
        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            let lines = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                var current = self.sessionLogs[serial] ?? []
                current.append(contentsOf: lines)
                if current.count > 100 {
                    current.removeFirst(current.count - 100)
                }
                self.sessionLogs[serial] = current
            }
        }
        
        process.terminationHandler = { [weak self] p in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.processes.removeValue(forKey: serial)
                self.activeSerials.remove(serial)
                
                // 更新 ADBService 中的设备镜像状态
                if let idx = ADBService.shared.devices.firstIndex(where: { $0.serial == serial }) {
                    ADBService.shared.devices[idx].isMirroring = false
                }
                
                var current = self.sessionLogs[serial] ?? []
                current.append("[系统] 投屏已退出 (返回码: \(p.terminationStatus))")
                self.sessionLogs[serial] = current
                
                // 关闭该设备关联的悬浮控制条
                FloatingToolbarWindowManager.shared.closeToolbar(for: serial)
            }
        }
        
        do {
            try process.run()
            self.processes[serial] = process
            self.activeSerials.insert(serial)
            
            if let idx = ADBService.shared.devices.firstIndex(where: { $0.serial == serial }) {
                ADBService.shared.devices[idx].isMirroring = true
            }
            
            // 自动开启伴随悬浮控制条
            FloatingToolbarWindowManager.shared.openToolbar(for: device)
        } catch {
            self.lastErrorMessage = "启动投屏失败: \(error.localizedDescription)"
            var current = self.sessionLogs[serial] ?? []
            current.append("[错误] 启动失败: \(error.localizedDescription)")
            self.sessionLogs[serial] = current
        }
    }
    
    /// 停止指定设备的投屏
    public func stopMirroring(serial: String) {
        if let process = processes[serial] {
            process.terminate()
            processes.removeValue(forKey: serial)
        }
        activeSerials.remove(serial)
        if let idx = ADBService.shared.devices.firstIndex(where: { $0.serial == serial }) {
            ADBService.shared.devices[idx].isMirroring = false
        }
        FloatingToolbarWindowManager.shared.closeToolbar(for: serial)
    }
    
    /// 停止所有投屏
    public func stopAll() {
        for (_, process) in processes {
            process.terminate()
        }
        processes.removeAll()
        activeSerials.removeAll()
        for i in 0..<ADBService.shared.devices.count {
            ADBService.shared.devices[i].isMirroring = false
        }
        FloatingToolbarWindowManager.shared.closeAll()
    }
}
