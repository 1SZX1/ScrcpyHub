import Foundation

public struct ScrcpyConfig: Codable, Equatable {
    // 画面与画质
    public var maxSize: Int = 0 // 0 = 原始，否则 1080, 1920, 2560 等
    public var bitRateMbps: Int = 16 // 4, 8, 12, 16, 24, 32
    public var maxFps: Int = 60 // 0 = 无限制, 30, 60, 90, 120
    public var videoCodec: String = "h264" // h264, h265, av1
    
    // 音频控制
    public var audioEnabled: Bool = true
    public var audioCodec: String = "opus" // opus, aac, raw
    
    // 运行行为与显示
    public var turnScreenOff: Bool = false
    public var stayAwake: Bool = true
    public var alwaysOnTop: Bool = false
    public var fullscreen: Bool = false
    public var showTouches: Bool = false
    public var readOnly: Bool = false
    public var displayOrientation: Int = 0 // 0, 90, 180, 270
    
    // 缓冲与高级
    public var displayBufferMs: Int = 0 // 0 = 禁用缓冲
    public var recordEnabled: Bool = false
    public var recordPath: String = ""
    public var customArgs: String = ""
    
    public init() {}
    
    /// 构建 scrcpy CLI 参数列表
    public func toArguments(serial: String? = nil) -> [String] {
        var args: [String] = []
        
        if let serial = serial, !serial.isEmpty {
            args.append(contentsOf: ["-s", serial])
        }
        
        if maxSize > 0 {
            args.append(contentsOf: ["--max-size", "\(maxSize)"])
        }
        
        if bitRateMbps > 0 {
            args.append(contentsOf: ["--video-bit-rate", "\(bitRateMbps)M"])
        }
        
        if maxFps > 0 {
            args.append(contentsOf: ["--max-fps", "\(maxFps)"])
        }
        
        if !videoCodec.isEmpty && videoCodec != "default" {
            args.append(contentsOf: ["--video-codec", videoCodec])
        }
        
        if !audioEnabled {
            args.append("--no-audio")
        } else if !audioCodec.isEmpty && audioCodec != "default" {
            args.append(contentsOf: ["--audio-codec", audioCodec])
        }
        
        if turnScreenOff {
            args.append("--turn-screen-off")
        }
        
        if stayAwake {
            args.append("--stay-awake")
        }
        
        if alwaysOnTop {
            args.append("--always-on-top")
        }
        
        if fullscreen {
            args.append("--fullscreen")
        }
        
        if showTouches {
            args.append("--show-touches")
        }
        
        if readOnly {
            args.append("--no-control")
        }
        
        if displayOrientation > 0 {
            args.append(contentsOf: ["--display-orientation", "\(displayOrientation)"])
        }
        
        if displayBufferMs > 0 {
            args.append(contentsOf: ["--display-buffer", "\(displayBufferMs)"])
        }
        
        if recordEnabled && !recordPath.isEmpty {
            args.append(contentsOf: ["--record", recordPath])
        }
        
        if !customArgs.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let parts = customArgs.components(separatedBy: " ").filter { !$0.isEmpty }
            args.append(contentsOf: parts)
        }
        
        return args
    }
    
    // MARK: - 默认配置持久化
    private static let defaultStorageKey = "ScrcpyHub_DefaultConfig_v1"
    
    /// 保存当前配置为系统的全局默认配置
    public func saveAsDefault() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.defaultStorageKey)
        }
    }
    
    /// 加载全局默认配置（若未自定义则返回出厂初始配置）
    public static func loadDefault() -> ScrcpyConfig {
        if let data = UserDefaults.standard.data(forKey: defaultStorageKey),
           let config = try? JSONDecoder().decode(ScrcpyConfig.self, from: data) {
            return config
        }
        return ScrcpyConfig()
    }
    
    /// 恢复出厂初始配置
    public static func resetToFactoryDefault() -> ScrcpyConfig {
        UserDefaults.standard.removeObject(forKey: defaultStorageKey)
        return ScrcpyConfig()
    }
}
