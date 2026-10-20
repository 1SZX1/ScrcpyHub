import Foundation

public struct PresetProfile: Identifiable, Equatable, Codable {
    public var id: String
    public var title: String
    public var subtitle: String
    public var iconName: String
    public var config: ScrcpyConfig
    public var isCustom: Bool
    
    public init(id: String = UUID().uuidString, title: String, subtitle: String, iconName: String, config: ScrcpyConfig, isCustom: Bool = false) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.config = config
        self.isCustom = isCustom
    }
    
    public static var builtInPresets: [PresetProfile] {
        [
            PresetProfile(
                id: "standard",
                title: "均衡流畅 (默认)",
                subtitle: "1080P · 16Mbps · 60FPS · 开启声音",
                iconName: "speedometer",
                config: {
                    var c = ScrcpyConfig()
                    c.maxSize = 1080
                    c.bitRateMbps = 16
                    c.maxFps = 60
                    c.videoCodec = "h264"
                    c.audioEnabled = true
                    c.stayAwake = true
                    return c
                }(),
                isCustom: false
            ),
            PresetProfile(
                id: "low_latency",
                title: "极限电竞 (超低延迟)",
                subtitle: "720P · 8Mbps · 120FPS · 零缓冲优化",
                iconName: "gamecontroller.fill",
                config: {
                    var c = ScrcpyConfig()
                    c.maxSize = 720
                    c.bitRateMbps = 8
                    c.maxFps = 120
                    c.videoCodec = "h264"
                    c.displayBufferMs = 0
                    c.stayAwake = true
                    return c
                }(),
                isCustom: false
            ),
            PresetProfile(
                id: "high_quality",
                title: "超清画质 (演示/录制)",
                subtitle: "2K/原始 · 24Mbps · H.265 · 高保真",
                iconName: "sparkles.tv.fill",
                config: {
                    var c = ScrcpyConfig()
                    c.maxSize = 0 // 原始分辨率
                    c.bitRateMbps = 24
                    c.maxFps = 60
                    c.videoCodec = "h265"
                    c.audioEnabled = true
                    c.stayAwake = true
                    return c
                }(),
                isCustom: false
            ),
            PresetProfile(
                id: "office_stealth",
                title: "息屏办公 (省电摸鱼)",
                subtitle: "手机息屏 · 保持唤醒 · 窗口置顶",
                iconName: "laptopcomputer.and.iphone",
                config: {
                    var c = ScrcpyConfig()
                    c.maxSize = 1080
                    c.bitRateMbps = 12
                    c.maxFps = 60
                    c.turnScreenOff = true
                    c.stayAwake = true
                    c.alwaysOnTop = true
                    return c
                }(),
                isCustom: false
            ),
            PresetProfile(
                id: "wireless_stable",
                title: "无线优化 (抗抖动)",
                subtitle: "720P · 6Mbps · 50ms 缓冲防丢帧",
                iconName: "wifi",
                config: {
                    var c = ScrcpyConfig()
                    c.maxSize = 720
                    c.bitRateMbps = 6
                    c.maxFps = 60
                    c.videoCodec = "h264"
                    c.displayBufferMs = 50
                    c.stayAwake = true
                    return c
                }(),
                isCustom: false
            )
        ]
    }
}
