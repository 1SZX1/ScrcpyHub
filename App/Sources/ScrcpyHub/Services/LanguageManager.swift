import SwiftUI
import Combine

public enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case zhHans = "zh-Hans"
    case en = "en"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .system:
            return LanguageManager.shared.isChinese ? "跟随系统" : "Follow System"
        case .zhHans:
            return "简体中文"
        case .en:
            return "English"
        }
    }
}

public final class LanguageManager: ObservableObject {
    public static let shared = LanguageManager()
    
    private let userDefaultsKey = "scrcpyhub_preferred_language"
    
    @Published public var selectedLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: userDefaultsKey)
            updateResolvedLanguage()
        }
    }
    
    @Published public private(set) var resolvedLanguage: AppLanguage = .zhHans
    
    public var isChinese: Bool {
        resolvedLanguage == .zhHans
    }
    
    private init() {
        let saved = UserDefaults.standard.string(forKey: userDefaultsKey) ?? AppLanguage.system.rawValue
        self.selectedLanguage = AppLanguage(rawValue: saved) ?? .system
        updateResolvedLanguage()
    }
    
    private func updateResolvedLanguage() {
        if selectedLanguage == .system {
            let preferred = Locale.preferredLanguages.first?.lowercased() ?? "zh"
            if preferred.contains("zh") {
                resolvedLanguage = .zhHans
            } else {
                resolvedLanguage = .en
            }
        } else {
            resolvedLanguage = selectedLanguage
        }
    }
    
    /// 获取本地化字符串
    public func t(_ key: String) -> String {
        let lang = resolvedLanguage == .zhHans ? "zh" : "en"
        return Self.translations[key]?[lang] ?? key
    }
    
    // MARK: - 集中翻译词典
    private static let translations: [String: [String: String]] = [
        // MARK: 通用 & 工具栏
        "app_title": ["zh": "ScrcpyHub - macOS 原生投屏与设备管理中心", "en": "ScrcpyHub - macOS Native Screen Mirroring & Manager"],
        "connected_devices": ["zh": "已连接设备", "en": "Connected Devices"],
        "devices_online_count": ["zh": "台设备在线", "en": "devices online"],
        "refresh_device_list": ["zh": "刷新设备列表", "en": "Refresh Devices"],
        "wireless_adb_wizard": ["zh": "无线 ADB 连接向导", "en": "Wireless ADB Wizard"],
        "connect_new_wireless": ["zh": "连接新无线设备...", "en": "Connect Wireless Device..."],
        "stop_all": ["zh": "停止全部", "en": "Stop All"],
        "adb_daemon_running": ["zh": "ADB 守护进程运行中", "en": "ADB Daemon Active"],
        "running_logs": ["zh": "运行日志", "en": "Logs"],
        "show_floating_toolbar": ["zh": "显示悬浮控制条", "en": "Show HUD Bar"],
        "status_mirroring": ["zh": "状态：正在投屏运行中", "en": "Status: Mirroring active"],
        "status_ready": ["zh": "状态：就绪，可随时开启投屏", "en": "Status: Ready to mirror"],
        "start_mirroring": ["zh": "立即启动投屏 (scrcpy)", "en": "Start Mirroring (scrcpy)"],
        "stop_mirroring": ["zh": "停止当前投屏", "en": "Stop Mirroring"],
        "please_select_device": ["zh": "请在左侧选择或连接一台 Android 设备", "en": "Please select or connect an Android device on the left"],
        "global_default_config": ["zh": "全局投屏默认配置", "en": "Global Default Configuration"],
        "select_device_hint": ["zh": "从左侧选择设备以开始投屏", "en": "Select a device on the left to start"],
        "language": ["zh": "语言", "en": "Language"],
        "follow_system": ["zh": "跟随系统", "en": "Follow System"],

        // MARK: 设备列表无设备引导
        "no_device_detected": ["zh": "未检测到 Android 设备", "en": "No Android Device Detected"],
        "troubleshooting_title": ["zh": "连接排查小建议：", "en": "Troubleshooting Tips:"],
        "troubleshooting_1": ["zh": "1. 确保手机已通过 USB 数据线连接 Mac", "en": "1. Ensure device is plugged in via USB"],
        "troubleshooting_2": ["zh": "2. 在手机【关于手机】连击版本号开启开发者选项", "en": "2. Tap Build Number 7 times in Settings to enable Dev Options"],
        "troubleshooting_3": ["zh": "3. 在【开发者选项】中开启【USB 调试】并信任此电脑", "en": "3. Turn on USB Debugging and authorize this computer"],
        "wireless_connect_action": ["zh": "无线连接设备...", "en": "Connect Wirelessly..."],

        // MARK: 设备卡片
        "mirroring_badge": ["zh": "投屏中", "en": "Mirroring"],
        "one_click_wireless": ["zh": "一键无线连接 (开启5555)", "en": "One-click Wireless Mode (TCP 5555)"],
        "disconnect_wireless": ["zh": "断开无线连接", "en": "Disconnect Wireless"],
        "copy_serial": ["zh": "复制设备 Serial", "en": "Copy Serial Number"],
        "quick_reboot": ["zh": "重启设备", "en": "Reboot Device"],
        "battery_charging": ["zh": "充电中", "en": "charging"],
        "battery_battery": ["zh": "电池", "en": "battery"],

        // MARK: 预设列表与卡片
        "quick_presets": ["zh": "快速场景预设", "en": "Quick Presets"],
        "save_as_preset": ["zh": "存为预设", "en": "Save Preset"],
        "save_as_preset_help": ["zh": "保存当前各项参数为一个独立的新预设", "en": "Save current parameters as a new preset profile"],
        "set_as_default": ["zh": "设为默认", "en": "Set Default"],
        "set_as_default_help": ["zh": "将当前参数保存为新设备接入时的全局默认启动配置", "en": "Save current parameters as global default for new devices"],
        "config_options": ["zh": "配置选项", "en": "Configuration Options"],
        "restore_factory_default": ["zh": "恢复出厂标准配置", "en": "Restore Factory Defaults"],
        "toast_saved_default": ["zh": "已将当前配置保存为全局默认", "en": "Saved as global default"],
        "toast_restored_factory": ["zh": "已重置为出厂标准配置", "en": "Restored to factory defaults"],
        "delete_custom_preset": ["zh": "删除此自定义预设", "en": "Delete custom preset"],
        "delete_preset": ["zh": "删除预设", "en": "Delete Preset"],

        // 预设名称与副标题
        "preset_balanced_title": ["zh": "均衡流畅 (默认)", "en": "Balanced (Default)"],
        "preset_balanced_sub": ["zh": "1080P · 16Mbps · 60FPS · 开启声音", "en": "1080P · 16Mbps · 60FPS · Audio On"],
        "preset_gaming_title": ["zh": "极限电竞 (超低延迟)", "en": "Ultra Gaming (Low Latency)"],
        "preset_gaming_sub": ["zh": "720P · 8Mbps · 120FPS · 零缓冲优化", "en": "720P · 8Mbps · 120FPS · 0ms Buffer"],
        "preset_presentation_title": ["zh": "超清画质 (演示 / 录制)", "en": "Ultra HD (Showcase / Record)"],
        "preset_presentation_sub": ["zh": "2K/原始 · 24Mbps · H.265 · 高保真", "en": "Native/2K · 24Mbps · H.265 · Lossless"],
        "preset_stealth_title": ["zh": "息屏办公 (省电摸鱼)", "en": "Stealth (Screen-Off)"],
        "preset_stealth_sub": ["zh": "手机息屏 · 保持唤醒 · 窗口置顶", "en": "Screen Off · Stay Awake · Always on Top"],
        "preset_wifi_title": ["zh": "无线优化 (抗抖动)", "en": "Wi-Fi Optimized (Anti-Jitter)"],
        "preset_wifi_sub": ["zh": "720P · 6Mbps · 50ms 缓冲防丢帧", "en": "720P · 6Mbps · 50ms Buffer"],

        // MARK: 设置分类选项卡
        "tab_video_perf": ["zh": "画面与性能", "en": "Video & Performance"],
        "tab_run_display": ["zh": "运行与显示", "en": "Display & Behavior"],
        "tab_audio_record": ["zh": "声音与录制", "en": "Audio & Record"],
        "tab_advanced_cli": ["zh": "高级与CLI", "en": "Advanced & CLI"],

        // MARK: 画面与性能项
        "max_size_limit": ["zh": "最大分辨率限制", "en": "Max Resolution Limit"],
        "res_native": ["zh": "原画 (跟随设备)", "en": "Native (Follow Device)"],
        "res_720": ["zh": "720P (1280x720)", "en": "720P (1280x720)"],
        "res_1080": ["zh": "1080P (1920x1080)", "en": "1080P (1920x1080)"],
        "res_1440": ["zh": "2K (2560x1440)", "en": "2K (2560x1440)"],
        "res_1920": ["zh": "全高清上限 (1920)", "en": "FHD Limit (1920)"],
        "video_bitrate": ["zh": "视频码率", "en": "Video Bitrate"],
        "bitrate_hint": ["zh": "码率越高画面越细腻，无线投屏建议设为 6~10 Mbps 避免延迟。", "en": "Higher bitrate gives cleaner video. 6-10 Mbps recommended for wireless to minimize latency."],
        "max_fps_limit": ["zh": "最大帧率上限", "en": "Max Frame Rate"],
        "fps_unlimited": ["zh": "不限制 (跟随屏幕)", "en": "Unlimited (Native Screen)"],
        "fps_30": ["zh": "30 FPS (省电流畅)", "en": "30 FPS (Power Saver)"],
        "fps_60": ["zh": "60 FPS (标准平滑)", "en": "60 FPS (Smooth Standard)"],
        "fps_90": ["zh": "90 FPS (高刷电竞)", "en": "90 FPS (High Refresh)"],
        "fps_120": ["zh": "120 FPS (极速极限)", "en": "120 FPS (Extreme High)"],
        "video_codec": ["zh": "视频编码格式", "en": "Video Codec"],
        "codec_h264": ["zh": "H.264 (兼容性最佳)", "en": "H.264 (Best Compatibility)"],
        "codec_h265": ["zh": "H.265 / HEVC (高压缩比)", "en": "H.265 / HEVC (High Efficiency)"],
        "codec_av1": ["zh": "AV1 (下一代编码，需设备支持)", "en": "AV1 (Next-Gen, Hardware Dependent)"],
        "display_buffer": ["zh": "画面渲染缓冲", "en": "Display Buffer"],
        "buffer_0": ["zh": "0 ms (无缓冲，超低延迟)", "en": "0 ms (Zero Buffer, Ultra Low Latency)"],
        "buffer_20": ["zh": "20 ms (微缓冲，轻度防抖)", "en": "20 ms (Micro Buffer)"],
        "buffer_50": ["zh": "50 ms (平衡，无线推荐)", "en": "50 ms (Balanced, Recommended for Wi-Fi)"],
        "buffer_100": ["zh": "100 ms (平滑，弱网专用)", "en": "100 ms (Smooth, High Jitter Network)"],

        // MARK: 运行与显示项
        "turn_screen_off": ["zh": "投屏开启时手机息屏", "en": "Turn Screen Off While Mirroring"],
        "turn_screen_off_desc": ["zh": "投屏时关闭安卓端物理屏幕以防发热耗电，可随时点按唤醒", "en": "Saves battery and reduces device heat while active"],
        "stay_awake": ["zh": "设备保持常亮不锁屏", "en": "Keep Device Awake"],
        "stay_awake_desc": ["zh": "阻止安卓设备在投屏期间因无操作而超时锁屏休眠", "en": "Prevents device from sleeping or locking automatically"],
        "always_on_top": ["zh": "投屏窗口总在最前", "en": "Always On Top Window"],
        "always_on_top_desc": ["zh": "投屏窗口置顶显示，避免被其他 Mac 应用窗口遮挡", "en": "Keeps mirroring window floating above all macOS apps"],
        "fullscreen": ["zh": "全屏模式启动", "en": "Start in Fullscreen Mode"],
        "show_touches": ["zh": "显示物理点击圆点 (Show Touches)", "en": "Show Physical Touch Dots"],
        "read_only": ["zh": "只读模式 (仅投屏监视，禁止控制输入)", "en": "Read-Only Mode (Monitor Only, Block Input)"],
        "display_orientation": ["zh": "强制画面旋转方向", "en": "Force Display Orientation"],
        "orient_sensor": ["zh": "默认 (跟随传感器方向)", "en": "Default (Sensor Orientation)"],
        "orient_90": ["zh": "逆时针 90° (横屏模式)", "en": "Counter-Clockwise 90° (Landscape)"],
        "orient_180": ["zh": "倒立 180°", "en": "Upside Down 180°"],
        "orient_270": ["zh": "顺时针 90°", "en": "Clockwise 90°"],

        // MARK: 声音与录制项
        "audio_sync": ["zh": "实时同步手机音频至 Mac", "en": "Forward Audio to Mac (Android 11+)"],
        "audio_sync_desc": ["zh": "需 Android 11+，手机游戏和媒体声音将实时通过 Mac 扬声器播放", "en": "Streams device game & media audio directly to Mac speakers"],
        "audio_codec": ["zh": "音频编码格式", "en": "Audio Codec"],
        "codec_opus": ["zh": "Opus (低延时高音质，推荐)", "en": "Opus (Low Latency & High Quality, Recommended)"],
        "codec_aac": ["zh": "AAC (通用兼容格式)", "en": "AAC (Broad Compatibility)"],
        "codec_raw": ["zh": "RAW (无损未压缩原始 PCM)", "en": "RAW (Lossless Uncompressed PCM)"],
        "record_enabled": ["zh": "开启投屏画面实时录制", "en": "Record Screen While Mirroring"],
        "record_desc": ["zh": "投屏同时将音视频无损录制为 MP4 视频文件", "en": "Saves mirroring stream into a lossless MP4 video file"],
        "record_path_placeholder": ["zh": "未选择录屏保存路径...", "en": "Select destination file path..."],
        "choose_location": ["zh": "选择存储路径...", "en": "Choose Location..."],

        // MARK: 高级与CLI
        "custom_cli_flags": ["zh": "自定义附加 scrcpy 参数 (Flags)", "en": "Custom CLI Arguments (Flags)"],
        "custom_flags_placeholder": ["zh": "例如: --window-x 100 --window-y 100 --prefer-text", "en": "e.g.: --window-x 100 --window-y 100 --prefer-text"],
        "cmd_preview": ["zh": "当前配置生成的完整启动命令预览：", "en": "Generated scrcpy Command Preview:"],

        // MARK: 保存预设弹窗
        "save_preset_title": ["zh": "保存当前配置为新预设", "en": "Save Configuration as New Preset"],
        "preset_name_label": ["zh": "预设名称：", "en": "Preset Name:"],
        "preset_name_placeholder": ["zh": "例如: 我的iPad扩展 / 极速高帧游戏", "en": "e.g.: My iPad Setup / High FPS Gaming"],
        "preset_desc_label": ["zh": "简短描述（留空将自动根据参数生成）：", "en": "Short Description (auto-generated if empty):"],
        "preset_desc_placeholder": ["zh": "例如: 1080P · 16Mbps · 60FPS", "en": "e.g.: 1080P · 16Mbps · 60FPS"],
        "preset_icon_label": ["zh": "预设图标：", "en": "Preset Icon:"],
        "key_parameters_summary": ["zh": "包含的关键参数：", "en": "Included Parameters:"],
        "cancel": ["zh": "取消", "en": "Cancel"],
        "save_as_new_preset": ["zh": "保存为新预设", "en": "Save Preset"],

        // MARK: 悬浮伴随控制条 (HUD)
        "drag_apk_file_hint": ["zh": "拖入 APK 安装或文件直传", "en": "Drop APK to install or files to push"],
        "key_back": ["zh": "返回键 (Back)", "en": "Back Button"],
        "key_home": ["zh": "主屏幕 (Home)", "en": "Home Screen"],
        "key_recents": ["zh": "多任务后台 (Recents)", "en": "Recent Apps"],
        "key_vol_down": ["zh": "音量减少", "en": "Volume Down"],
        "key_vol_up": ["zh": "音量增加", "en": "Volume Up"],
        "key_power": ["zh": "电源 / 息屏唤醒", "en": "Power / Lock Screen"],
        "key_notifications": ["zh": "下拉通知栏", "en": "Expand Notifications"],
        "key_screenshot": ["zh": "无损截屏并存入下载", "en": "Capture Screenshot to Downloads"],
        "close_dock": ["zh": "收起悬浮条", "en": "Hide HUD Bar"],
        "cancel_transfer": ["zh": "取消传输", "en": "Cancel Transfer"],
        "transfer_cancelled": ["zh": "已取消传输", "en": "Transfer cancelled"],
        "transfer_failed": ["zh": "传输失败", "en": "Transfer failed"],
        "install_failed": ["zh": "安装失败", "en": "Install failed"],
        "installing_apk": ["zh": "安装中...", "en": "Installing..."],
        "push_success": ["zh": "文件已成功推送到手机 Download 目录", "en": "File pushed to Download folder successfully"],
        "install_success": ["zh": "应用安装成功！", "en": "App installed successfully!"],

        // MARK: 无线连接向导
        "wireless_adb_wizard_title": ["zh": "无线 ADB 连接向导", "en": "Wireless ADB Connection Wizard"],
        "tab_pairing_code": ["zh": "🔢 6 位配对码 (Android 11+)", "en": "🔢 6-Digit Pairing Code (Android 11+)"],
        "tab_direct_ip": ["zh": "⚡️ 局域网直连 (默认 5555)", "en": "⚡️ Direct IP Connect (Default 5555)"],
        "pairing_code_guide_title": ["zh": "在手机【开发者选项 -> 无线调试 -> 使用配对码配对设备】弹窗中查看：", "en": "On device: Developer options > Wireless debugging > Pair device with pairing code:"],
        "pair_ip_placeholder": ["zh": "配对 IP (例如 192.168.31.142)", "en": "Pairing IP (e.g. 192.168.31.142)"],
        "port": ["zh": "端口", "en": "Port"],
        "pairing_code_placeholder": ["zh": "6 位配对验证码 (例如 849201)", "en": "6-digit pairing code (e.g. 849201)"],
        "pair_and_connect_action": ["zh": "立即配对并连接", "en": "Pair & Connect Now"],
        "direct_ip_guide_title": ["zh": "输入手机局域网 IP 地址及端口（需先在手机端通过有线或终端开启 5555 端口）：", "en": "Enter device local IP address and port (requires port 5555 opened beforehand):"],
        "connect_now_action": ["zh": "立即连接", "en": "Connect Now"],
        "connecting_to": ["zh": "正在连接", "en": "Connecting to"],
        "pairing_with": ["zh": "正在向安全配对", "en": "Pairing securely with"],
        "connect_success": ["zh": "连接成功！", "en": "Connected successfully! "],
        "pair_success_joined": ["zh": "已成功加入设备池！", "en": "Paired & added to device pool! "],
        "pair_success_connecting": ["zh": "配对成功！正在建立调试连接...", "en": "Paired! Establishing connection..."],
        "pair_failed": ["zh": "配对失败: ", "en": "Pairing failed: "],

        // MARK: 菜单栏 (Menu Bar Extra)
        "menubar_online_devices": ["zh": "在线设备", "en": "Online Devices"],
        "menubar_no_devices": ["zh": "未检测到 Android 设备", "en": "No Android Device Detected"],
        "menubar_start_mirror": ["zh": "启动投屏: ", "en": "Start Mirroring: "],
        "menubar_stop_mirror": ["zh": "停止投屏: ", "en": "Stop Mirroring: "],
        "menubar_open_console": ["zh": "打开主控制面板", "en": "Open Main Console"],
        "menubar_refresh": ["zh": "刷新设备列表", "en": "Refresh Devices"],
        "menubar_quit": ["zh": "退出 ScrcpyHub", "en": "Quit ScrcpyHub"],
        "menubar_language": ["zh": "切换界面语言", "en": "Language"]
    ]
}

/// 全局便捷访问工具扩展
public func t(_ key: String) -> String {
    LanguageManager.shared.t(key)
}
