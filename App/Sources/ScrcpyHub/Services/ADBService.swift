import Foundation
import Combine
import Darwin

@MainActor
public final class ADBService: ObservableObject {
    public static let shared = ADBService()
    
    @Published public var devices: [Device] = []
    @Published public var isRefreshing: Bool = false
    @Published public var lastMessage: String = ""
    @Published public var lastError: String? = nil
    
    private var timer: Timer?
    private var queryingSerials = Set<String>()
    private var knownMarketNames: [String: String] = [:]
    
    private init() {
        startMonitoring()
    }
    
    public func startMonitoring() {
        timer?.invalidate()
        refreshDevices()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshDevices(isManual: false)
            }
        }
    }
    
    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    /// 刷新已连接设备列表
    public func refreshDevices(isManual: Bool = false) {
        if isManual {
            isRefreshing = true
        }
        
        Task.detached(priority: .userInitiated) {
            let adb = BinaryLocator.shared.adbPath()
            let output = await Self.runCommand(executable: adb, arguments: ["devices", "-l"])
            let parsedDevices = Self.parseDevicesOutput(output)
            
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                
                // 保留旧设备的 isMirroring 状态与已查询属性
                var updatedList: [Device] = []
                for var newDev in parsedDevices {
                    let cachedMarket = self.knownMarketNames[newDev.serial]
                    if let existing = self.devices.first(where: { $0.serial == newDev.serial }) {
                        newDev.isMirroring = existing.isMirroring
                        newDev.batteryLevel = existing.batteryLevel
                        newDev.isCharging = existing.isCharging
                        newDev.resolution = existing.resolution
                        newDev.marketName = cachedMarket ?? existing.marketName
                        if let m = cachedMarket ?? existing.marketName, !m.isEmpty {
                            newDev.model = m
                        }
                    } else if let cachedMarket = cachedMarket {
                        newDev.marketName = cachedMarket
                        newDev.model = cachedMarket
                    }
                    updatedList.append(newDev)
                }
                
                self.devices = updatedList
                if isManual {
                    self.isRefreshing = false
                }
            }
            
            // 异步深采每台可用设备的信息 (名称、电池、分辨率)
            for dev in parsedDevices where dev.state == .device {
                await self.fetchDetailedInfo(for: dev.serial)
            }
        }
    }
    
    /// 深入读取具体设备的商用名、电量及物理分辨率
    private func fetchDetailedInfo(for serial: String) async {
        guard !queryingSerials.contains(serial) else { return }
        queryingSerials.insert(serial)
        defer { queryingSerials.remove(serial) }
        
        let adb = BinaryLocator.shared.adbPath()
        
        // 1. 获取商业市场名称 (已缓存则直接跳过查询，避免频繁 adb shell 刷新)
        let needQueryMarket = await MainActor.run { self.knownMarketNames[serial] == nil }
        var fetchedMarketName: String? = nil
        if needQueryMarket {
            let out = await Self.runCommand(executable: adb, arguments: [
                "-s", serial, "shell", "getprop ro.product.marketname 2>/dev/null || getprop ro.product.model"
            ]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !out.isEmpty && !out.contains("error") {
                fetchedMarketName = out
            }
        }
        
        // 2. 获取电池状态
        let batteryOutput = await Self.runCommand(executable: adb, arguments: ["-s", serial, "shell", "dumpsys", "battery"])
        var batteryLevel: Int? = nil
        var isCharging: Bool? = nil
        for line in batteryOutput.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.starts(with: "level:") {
                let parts = trimmed.components(separatedBy: ":")
                if parts.count > 1, let lvl = Int(parts[1].trimmingCharacters(in: .whitespaces)) {
                    batteryLevel = lvl
                }
            }
            if trimmed.starts(with: "status:") {
                let parts = trimmed.components(separatedBy: ":")
                if parts.count > 1, let st = Int(parts[1].trimmingCharacters(in: .whitespaces)) {
                    isCharging = (st == 2) // 2: BATTERY_STATUS_CHARGING
                }
            }
        }
        
        // 3. 获取屏幕分辨率
        let wmOutput = await Self.runCommand(executable: adb, arguments: ["-s", serial, "shell", "wm", "size"])
        var resolution: String? = nil
        for line in wmOutput.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.contains("size:") {
                let parts = trimmed.components(separatedBy: ":")
                if parts.count > 1 {
                    resolution = parts[1].trimmingCharacters(in: .whitespaces)
                }
            }
        }
        
        await MainActor.run { [weak self] in
            guard let self = self else { return }
            if let market = fetchedMarketName {
                self.knownMarketNames[serial] = market
            }
            if let idx = self.devices.firstIndex(where: { $0.serial == serial }) {
                if let market = self.knownMarketNames[serial] {
                    self.devices[idx].marketName = market
                    self.devices[idx].model = market
                }
                if let batteryLevel = batteryLevel {
                    self.devices[idx].batteryLevel = batteryLevel
                }
                if let isCharging = isCharging {
                    self.devices[idx].isCharging = isCharging
                }
                if let resolution = resolution {
                    self.devices[idx].resolution = resolution
                }
            }
        }
    }
    
    /// 解析 adb devices -l 输出
    nonisolated public static func parseDevicesOutput(_ output: String) -> [Device] {
        var result: [Device] = []
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.starts(with: "List of devices") || trimmed.starts(with: "* daemon") {
                continue
            }
            
            let components = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            guard !components.isEmpty else { continue }
            
            let serial = components[0]
            let stateStr = components.count > 1 ? components[1] : "unknown"
            
            var state: DeviceState = .unknown
            switch stateStr.lowercased() {
            case "device": state = .device
            case "unauthorized": state = .unauthorized
            case "offline": state = .offline
            case "recovery": state = .recovery
            default: state = .unknown
            }
            
            var model = ""
            var product = ""
            var deviceName = ""
            
            for item in components.dropFirst(2) {
                if item.starts(with: "model:") {
                    model = String(item.dropFirst(6))
                } else if item.starts(with: "product:") {
                    product = String(item.dropFirst(8))
                } else if item.starts(with: "device:") {
                    deviceName = String(item.dropFirst(7))
                }
            }
            
            let connectionType: ConnectionType = (serial.contains(":") || serial.contains(".")) ? .wifi : .usb
            let dev = Device(
                serial: serial,
                model: model.isEmpty ? (deviceName.isEmpty ? "Android 设备" : deviceName) : model,
                product: product,
                deviceName: deviceName,
                state: state,
                connectionType: connectionType
            )
            result.append(dev)
        }
        return result
    }
    
    /// 读取设备的 Wi-Fi 局域网 IP
    public func getDeviceWifiIp(serial: String) async -> String? {
        let adb = BinaryLocator.shared.adbPath()
        let cmd = "ip addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1"
        let out = await Self.runCommand(executable: adb, arguments: ["-s", serial, "shell", cmd])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !out.isEmpty && out.contains(".") {
            return out
        }
        return nil
    }
    
    /// 将 USB 设备一键切换为无线 TCP/IP 模式并直连
    public func enableWirelessAndConnect(serial: String, port: Int = 5555) async -> Result<String, Error> {
        let adb = BinaryLocator.shared.adbPath()
        // 1. 获取 IP
        guard let ip = await getDeviceWifiIp(serial: serial) else {
            return .failure(NSError(domain: "ADB", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法获取手机 Wi-Fi 局域网 IP，请确保手机已连接同一 Wi-Fi"]))
        }
        
        // 2. 开启 tcpip
        let tcpipOut = await Self.runCommand(executable: adb, arguments: ["-s", serial, "tcpip", "\(port)"])
        if tcpipOut.contains("error") {
            return .failure(NSError(domain: "ADB", code: 2, userInfo: [NSLocalizedDescriptionKey: "设置 tcpip 失败: \(tcpipOut)"]))
        }
        
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 等待 1 秒
        
        // 3. connect
        let target = "\(ip):\(port)"
        let connectOut = await Self.runCommand(executable: adb, arguments: ["connect", target])
        if connectOut.contains("connected to") {
            refreshDevices(isManual: true)
            return .success(target)
        } else {
            return .failure(NSError(domain: "ADB", code: 3, userInfo: [NSLocalizedDescriptionKey: "连接失败: \(connectOut)"]))
        }
    }
    
    /// 手动输入 IP 连接无线设备
    public func connectWireless(address: String) async -> Result<String, Error> {
        let adb = BinaryLocator.shared.adbPath()
        let connectOut = await Self.runCommand(executable: adb, arguments: ["connect", address])
        if connectOut.contains("connected to") || connectOut.contains("already connected") {
            refreshDevices(isManual: true)
            return .success(connectOut.trimmingCharacters(in: .whitespacesAndNewlines))
        } else {
            return .failure(NSError(domain: "ADB", code: 4, userInfo: [NSLocalizedDescriptionKey: connectOut.trimmingCharacters(in: .whitespacesAndNewlines)]))
        }
    }
    
    /// Android 11+ 配对码配对
    public func pairWireless(address: String, code: String) async -> Result<String, Error> {
        let adb = BinaryLocator.shared.adbPath()
        let pairOut = await Self.runCommand(executable: adb, arguments: ["pair", address, code])
        if pairOut.contains("Successfully paired") {
            return .success(pairOut.trimmingCharacters(in: .whitespacesAndNewlines))
        } else {
            return .failure(NSError(domain: "ADB", code: 5, userInfo: [NSLocalizedDescriptionKey: pairOut.trimmingCharacters(in: .whitespacesAndNewlines)]))
        }
    }
    
    /// 获取当前 mDNS 发现的服务列表
    public func getMdnsServices() async -> [(name: String, type: String, address: String)] {
        let adb = BinaryLocator.shared.adbPath()
        let out = await Self.runCommand(executable: adb, arguments: ["mdns", "services"])
        var services: [(name: String, type: String, address: String)] = []
        for line in out.components(separatedBy: .newlines) {
            let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            if parts.count >= 3 {
                let name = parts[0]
                let type = parts[1]
                let address = parts[2]
                services.append((name: name, type: type, address: address))
            }
        }
        return services
    }
    
    /// 发送物理按键事件 (KeyEvent)
    public func sendKeyevent(serial: String, keycode: Int) {
        Task.detached(priority: .userInitiated) {
            let adb = BinaryLocator.shared.adbPath()
            _ = await Self.runCommand(executable: adb, arguments: ["-s", serial, "shell", "input", "keyevent", "\(keycode)"])
        }
    }
    
    /// 下拉展开通知栏
    public func expandNotifications(serial: String) {
        Task.detached(priority: .userInitiated) {
            let adb = BinaryLocator.shared.adbPath()
            _ = await Self.runCommand(executable: adb, arguments: ["-s", serial, "shell", "cmd", "statusbar", "expand-notifications"])
        }
    }
    
    /// 截屏并保存到 Mac 的 Downloads 目录
    public func takeScreenshot(serial: String) async -> Result<URL, Error> {
        let adb = BinaryLocator.shared.adbPath()
        let filename = "Screenshot_\(Date().timeIntervalSince1970).png"
        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: "/tmp")
        let destinationUrl = downloads.appendingPathComponent(filename)
        
        let tempRemotePath = "/sdcard/scrcpy_hub_temp.png"
        _ = await Self.runCommand(executable: adb, arguments: ["-s", serial, "shell", "screencap", "-p", tempRemotePath])
        let pullOut = await Self.runCommand(executable: adb, arguments: ["-s", serial, "pull", tempRemotePath, destinationUrl.path])
        _ = await Self.runCommand(executable: adb, arguments: ["-s", serial, "shell", "rm", "-f", tempRemotePath])
        
        if FileManager.default.fileExists(atPath: destinationUrl.path) {
            return .success(destinationUrl)
        } else {
            return .failure(NSError(domain: "ADB", code: 6, userInfo: [NSLocalizedDescriptionKey: "截屏保存失败: \(pullOut)"]))
        }
    }
    
    /// 安装 APK 到手机
    public func installApk(serial: String, fileUrl: URL) async -> Result<String, Error> {
        await installApkWithProgress(serial: serial, fileUrl: fileUrl, onProcessReady: nil)
    }
    
    /// 安装 APK 到手机（支持外部中断取消）
    public func installApkWithProgress(
        serial: String,
        fileUrl: URL,
        onProcessReady: (@Sendable (Process) -> Void)? = nil
    ) async -> Result<String, Error> {
        let adb = BinaryLocator.shared.adbPath()
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: adb)
                process.arguments = ["-s", serial, "install", "-r", fileUrl.path]
                
                var env = ProcessInfo.processInfo.environment
                env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:" + (env["PATH"] ?? "")
                process.environment = env
                
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe
                
                do {
                    try process.run()
                    onProcessReady?(process)
                    
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    process.waitUntilExit()
                    let out = String(data: data, encoding: .utf8) ?? ""
                    
                    if out.contains("Success") {
                        continuation.resume(returning: .success(t("install_success")))
                    } else if process.terminationReason == .uncaughtSignal {
                        continuation.resume(returning: .failure(NSError(domain: "ADB", code: -1, userInfo: [NSLocalizedDescriptionKey: t("transfer_cancelled")])))
                    } else {
                        continuation.resume(returning: .failure(NSError(domain: "ADB", code: 7, userInfo: [NSLocalizedDescriptionKey: "\(t("install_failed")): \(out.trimmingCharacters(in: .whitespacesAndNewlines))"])))
                    }
                } catch {
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
    
    /// 推送文件到手机 Download 目录
    public func pushFile(serial: String, fileUrl: URL) async -> Result<String, Error> {
        await pushFileWithProgress(serial: serial, fileUrl: fileUrl, onProgress: { _ in }, onProcessReady: nil)
    }
    
    /// 推送文件到手机 Download 目录（支持实时百分比进度回调与外部中断取消）
    public func pushFileWithProgress(
        serial: String,
        fileUrl: URL,
        onProgress: @escaping @Sendable (Double) -> Void,
        onProcessReady: (@Sendable (Process) -> Void)? = nil
    ) async -> Result<String, Error> {
        let adb = BinaryLocator.shared.adbPath()
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var ws = winsize(ws_row: 24, ws_col: 80, ws_xpixel: 0, ws_ypixel: 0)
                var masterFd: Int32 = 0
                var slaveFd: Int32 = 0
                guard openpty(&masterFd, &slaveFd, nil, nil, &ws) == 0 else {
                    continuation.resume(returning: .failure(NSError(domain: "ADB", code: 9, userInfo: [NSLocalizedDescriptionKey: "无法创建伪终端 PTY"])))
                    return
                }
                
                let process = Process()
                process.executableURL = URL(fileURLWithPath: adb)
                process.arguments = ["-s", serial, "push", fileUrl.path, "/sdcard/Download/"]
                
                var env = ProcessInfo.processInfo.environment
                env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:" + (env["PATH"] ?? "")
                env["TERM"] = "xterm-256color"
                process.environment = env
                
                let slaveHandle = FileHandle(fileDescriptor: slaveFd, closeOnDealloc: true)
                process.standardOutput = slaveHandle
                process.standardError = slaveHandle
                
                do {
                    try process.run()
                    onProcessReady?(process)
                    close(slaveFd)
                    
                    let masterHandle = FileHandle(fileDescriptor: masterFd, closeOnDealloc: true)
                    var outputData = Data()
                    var buffer = ""
                    let regex = try? NSRegularExpression(pattern: #"\[\s*(\d+)%\]"#)
                    
                    while true {
                        let chunk = masterHandle.availableData
                        if chunk.isEmpty { break }
                        outputData.append(chunk)
                        if let str = String(data: chunk, encoding: .utf8) {
                            buffer.append(str)
                            if buffer.count > 512 {
                                buffer = String(buffer.suffix(256))
                            }
                            let nsStr = buffer as NSString
                            let matches = regex?.matches(in: buffer, range: NSRange(location: 0, length: nsStr.length)) ?? []
                            if let last = matches.last, last.numberOfRanges > 1 {
                                let percentStr = nsStr.substring(with: last.range(at: 1))
                                if let val = Double(percentStr) {
                                    onProgress(min(max(val / 100.0, 0.0), 1.0))
                                }
                            }
                        }
                    }
                    
                    process.waitUntilExit()
                    close(masterFd)
                    
                    let out = String(data: outputData, encoding: .utf8) ?? ""
                    if process.terminationStatus == 0 || out.contains("pushed") {
                        onProgress(1.0)
                        continuation.resume(returning: .success(t("push_success")))
                    } else if process.terminationReason == .uncaughtSignal {
                        continuation.resume(returning: .failure(NSError(domain: "ADB", code: -1, userInfo: [NSLocalizedDescriptionKey: t("transfer_cancelled")])))
                    } else {
                        continuation.resume(returning: .failure(NSError(domain: "ADB", code: 8, userInfo: [NSLocalizedDescriptionKey: "\(t("transfer_failed")): \(out.trimmingCharacters(in: .whitespacesAndNewlines))"])))
                    }
                } catch {
                    close(masterFd)
                    close(slaveFd)
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
    
    // MARK: - 底层命令执行
    nonisolated public static func runCommand(executable: String, arguments: [String]) async -> String {
        return await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            
            var env = ProcessInfo.processInfo.environment
            env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:" + (env["PATH"] ?? "")
            process.environment = env
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            do {
                try process.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                let output = String(data: data, encoding: .utf8) ?? ""
                continuation.resume(returning: output)
            } catch {
                continuation.resume(returning: "Error running command: \(error.localizedDescription)")
            }
        }
    }
}
