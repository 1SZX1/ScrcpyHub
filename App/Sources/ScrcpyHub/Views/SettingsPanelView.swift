import SwiftUI

public struct SettingsPanelView: View {
    @Binding public var config: ScrcpyConfig
    public let activeDevice: Device?
    
    @ObservedObject private var presetManager = PresetManager.shared
    @State private var selectedCategory: Int = 0
    @State private var isShowingSavePresetSheet: Bool = false
    @State private var toastMessage: String? = nil
    
    public init(config: Binding<ScrcpyConfig>, activeDevice: Device?) {
        self._config = config
        self.activeDevice = activeDevice
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // 场景预设选择区 (自适应网格折行排布)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                        .foregroundColor(.accentColor)
                    Text("快速场景预设")
                        .font(.headline)
                    
                    Spacer()
                    
                    // 保存为自定义预设
                    Button(action: { isShowingSavePresetSheet = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("保存为预设")
                        }
                        .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("将当前调整好的各项参数保存为一个新的快捷预设方案")
                    
                    // 保存为全局默认配置
                    Button(action: {
                        config.saveAsDefault()
                        showToast("已将当前参数保存为启动默认配置！")
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "pin.fill")
                            Text("设为默认")
                        }
                        .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("将当前参数保存为全局默认配置，下次打开软件或新设备自动采用")
                    
                    // 更多设置（恢复出厂）
                    Menu {
                        Button("恢复出厂默认配置") {
                            config = ScrcpyConfig.resetToFactoryDefault()
                            showToast("已恢复出厂初始配置！")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .help("配置选项（恢复出厂配置）")
                }
                
                if let toast = toastMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 11))
                        Text(toast)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.green.opacity(0.12))
                    .cornerRadius(6)
                    .transition(.opacity)
                }
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: 240), spacing: 8)], spacing: 8) {
                    ForEach(presetManager.allPresets) { preset in
                        PresetCard(preset: preset, isCurrent: isPresetActive(preset), onApply: {
                            config = preset.config
                        }, onDelete: {
                            presetManager.deletePreset(id: preset.id)
                        })
                    }
                }
                .padding(.vertical, 4)
            }
            .padding(14)
            .background(Color.primary.opacity(0.02))
            
            Divider()
            
            // 分类选项卡
            Picker("", selection: $selectedCategory) {
                Text("画面与性能").tag(0)
                Text("运行与显示").tag(1)
                Text("声音与录制").tag(2)
                Text("高级与指令").tag(3)
            }
            .pickerStyle(.segmented)
            .padding(12)
            
            // 详细参数调节
            ScrollView {
                VStack(spacing: 16) {
                    if selectedCategory == 0 {
                        videoSettingsView
                    } else if selectedCategory == 1 {
                        behaviorSettingsView
                    } else if selectedCategory == 2 {
                        audioAndRecordSettingsView
                    } else {
                        advancedSettingsView
                    }
                }
                .padding(16)
            }
        }
        .sheet(isPresented: $isShowingSavePresetSheet) {
            SavePresetSheet(currentConfig: config)
        }
    }
    
    // MARK: - 画面与性能
    private var videoSettingsView: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 分辨率
            HStack {
                Label("最大分辨率限制", systemImage: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")
                    .frame(width: 160, alignment: .leading)
                
                Picker("", selection: $config.maxSize) {
                    Text("原始分辨率 (不限制)").tag(0)
                    Text("720P (流畅省资源)").tag(720)
                    Text("1080P (高清推荐)").tag(1080)
                    Text("1440P (2K)").tag(1440)
                    Text("1920P (高分屏)").tag(1920)
                }
                .pickerStyle(.menu)
            }
            
            // 码率调节
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("视频码率", systemImage: "gauge.with.needle")
                        .frame(width: 160, alignment: .leading)
                    
                    Slider(value: Binding(
                        get: { Double(config.bitRateMbps) },
                        set: { config.bitRateMbps = Int($0) }
                    ), in: 2...40, step: 2)
                    
                    Text("\(config.bitRateMbps) Mbps")
                        .font(.system(size: 12, design: .monospaced))
                        .frame(width: 65, alignment: .trailing)
                }
                Text("码率越高画面越细腻，无线投屏建议设为 6~10 Mbps 避免延迟。")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.leading, 164)
            }
            
            // 帧率上限
            HStack {
                Label("最大帧率上限", systemImage: "timer")
                    .frame(width: 160, alignment: .leading)
                
                Picker("", selection: $config.maxFps) {
                    Text("无限制 (按手机刷新率)").tag(0)
                    Text("30 FPS (节能)").tag(30)
                    Text("60 FPS (流畅)").tag(60)
                    Text("90 FPS (高刷)").tag(90)
                    Text("120 FPS (电竞高刷)").tag(120)
                }
                .pickerStyle(.menu)
            }
            
            // 编解码器
            HStack {
                Label("视频编码格式", systemImage: "film")
                    .frame(width: 160, alignment: .leading)
                
                Picker("", selection: $config.videoCodec) {
                    Text("H.264 (兼容性最佳)").tag("h264")
                    Text("H.265 / HEVC (高压缩比/省带宽)").tag("h265")
                    Text("AV1 (下一代高效编码)").tag("av1")
                }
                .pickerStyle(.menu)
            }
            
            // 缓冲延时
            HStack {
                Label("画面渲染缓冲", systemImage: "water.waves")
                    .frame(width: 160, alignment: .leading)
                
                Picker("", selection: $config.displayBufferMs) {
                    Text("0 ms (极速零延迟)").tag(0)
                    Text("20 ms (微缓冲)").tag(20)
                    Text("50 ms (无线抗抖动推荐)").tag(50)
                    Text("100 ms (弱网防卡顿)").tag(100)
                }
                .pickerStyle(.menu)
            }
        }
    }
    
    // MARK: - 运行与显示
    private var behaviorSettingsView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle(isOn: $config.turnScreenOff) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("熄屏投屏 (--turn-screen-off)")
                        .font(.system(size: 13, weight: .medium))
                    Text("投屏开始后手机屏幕自动熄灭，电脑仍可全功能触控操作，显著降低手机发热与耗电。")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Toggle(isOn: $config.stayAwake) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("保持设备常亮 (--stay-awake)")
                        .font(.system(size: 13, weight: .medium))
                    Text("连接投屏期间阻止手机自动休眠锁定。")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Toggle(isOn: $config.alwaysOnTop) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("窗口始终置顶 (--always-on-top)")
                        .font(.system(size: 13, weight: .medium))
                    Text("投屏窗口将置于其他所有 macOS 应用程序窗口上方。")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Toggle(isOn: $config.fullscreen) {
                Text("全屏启动投屏 (--fullscreen)")
                    .font(.system(size: 13, weight: .medium))
            }
            
            Toggle(isOn: $config.showTouches) {
                Text("在手机上高亮显示物理触摸圆点 (--show-touches)")
                    .font(.system(size: 13, weight: .medium))
            }
            
            Toggle(isOn: $config.readOnly) {
                Text("只读模式 / 禁用控制 (--no-control)")
                    .font(.system(size: 13, weight: .medium))
            }
            
            HStack {
                Label("画面旋转方向", systemImage: "rotate.right")
                    .frame(width: 160, alignment: .leading)
                
                Picker("", selection: $config.displayOrientation) {
                    Text("跟随手机传感器 (默认)").tag(0)
                    Text("顺时针旋转 90°").tag(90)
                    Text("旋转 180° (倒置)").tag(180)
                    Text("顺时针旋转 270°").tag(270)
                }
                .pickerStyle(.menu)
            }
        }
    }
    
    // MARK: - 声音与录制
    private var audioAndRecordSettingsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 音频开关
            Toggle(isOn: $config.audioEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("开启音频实时同步")
                        .font(.system(size: 13, weight: .medium))
                    Text("将手机应用及游戏声音实时转发至 Mac 扬声器播放 (要求 Android 11+)。")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if config.audioEnabled {
                HStack {
                    Label("音频编码格式", systemImage: "waveform")
                        .frame(width: 160, alignment: .leading)
                    
                    Picker("", selection: $config.audioCodec) {
                        Text("Opus (默认/低延迟)").tag("opus")
                        Text("AAC (高兼容)").tag("aac")
                        Text("RAW (无损 PCM)").tag("raw")
                    }
                    .pickerStyle(.menu)
                }
            }
            
            Divider()
            
            // 录屏设置
            Toggle(isOn: $config.recordEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("启动投屏时自动录制到本地文件 (--record)")
                        .font(.system(size: 13, weight: .medium))
                    Text("将手机画面以 mp4 格式同步存盘。")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if config.recordEnabled {
                HStack {
                    TextField("录像保存文件路径 (如 ~/Downloads/record.mp4)", text: $config.recordPath)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("选择位置...") {
                        selectSaveRecordPath()
                    }
                }
            }
        }
    }
    
    // MARK: - 高级与指令
    private var advancedSettingsView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("自定义附加命令行参数 (CLI Flags)")
                .font(.system(size: 13, weight: .semibold))
            
            TextField("例如: --window-x 100 --window-y 100 --prefer-text", text: $config.customArgs)
                .textFieldStyle(.roundedBorder)
            
            Text("当前配置生成的完整启动命令预览：")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.top, 4)
            
            let cmdPreview = "scrcpy " + config.toArguments(serial: activeDevice?.serial ?? "<device_serial>").joined(separator: " ")
            Text(cmdPreview)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.accentColor)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(0.04))
                .cornerRadius(6)
        }
    }
    
    private func isPresetActive(_ preset: PresetProfile) -> Bool {
        return config.maxSize == preset.config.maxSize &&
               config.bitRateMbps == preset.config.bitRateMbps &&
               config.maxFps == preset.config.maxFps &&
               config.videoCodec == preset.config.videoCodec &&
               config.turnScreenOff == preset.config.turnScreenOff
    }
    
    private func selectSaveRecordPath() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.mpeg4Movie]
        panel.nameFieldStringValue = "ScrcpyRecord_\(Int(Date().timeIntervalSince1970)).mp4"
        if panel.runModal() == .OK, let url = panel.url {
            config.recordPath = url.path
        }
    }
    
    private func showToast(_ message: String) {
        withAnimation {
            toastMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if self.toastMessage == message {
                withAnimation {
                    self.toastMessage = nil
                }
            }
        }
    }
}

struct PresetCard: View {
    let preset: PresetProfile
    let isCurrent: Bool
    let onApply: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: onApply) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Image(systemName: preset.iconName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isCurrent ? .white : .accentColor)
                    
                    Text(preset.title)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isCurrent ? .white : .primary)
                        .lineLimit(1)
                    
                    Spacer(minLength: 0)
                    
                    if preset.isCustom {
                        Button(action: onDelete) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(isCurrent ? .white.opacity(0.8) : .secondary)
                        }
                        .buttonStyle(.plain)
                        .help("删除此自定义预设")
                    }
                }
                
                Text(preset.subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(isCurrent ? .white.opacity(0.85) : .secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isCurrent ? Color.accentColor : Color.primary.opacity(isHovered ? 0.08 : 0.04))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isCurrent ? Color.accentColor : Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .contextMenu {
            if preset.isCustom {
                Button(role: .destructive, action: onDelete) {
                    Label("删除预设", systemImage: "trash")
                }
            }
        }
    }
}

struct SavePresetSheet: View {
    let currentConfig: ScrcpyConfig
    @Environment(\.dismiss) private var dismiss
    
    @State private var presetTitle: String = ""
    @State private var presetSubtitle: String = ""
    @State private var selectedIcon: String = "star.fill"
    
    private let iconOptions = [
        "star.fill", "gamecontroller.fill", "sparkles.tv.fill", "speedometer",
        "laptopcomputer.and.iphone", "wifi", "bolt.fill", "film.fill", "display"
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.accentColor)
                    .font(.title3)
                Text("保存当前配置为新预设")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("预设名称：")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("例如: 我的iPad扩展 / 极速高帧游戏", text: $presetTitle)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("简短描述（留空将自动根据参数生成）：")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("例如: 1080P · 16Mbps · 60FPS", text: $presetSubtitle)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("预设图标：")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .font(.system(size: 13))
                                    .frame(width: 32, height: 32)
                                    .background(selectedIcon == icon ? Color.accentColor : Color.primary.opacity(0.06))
                                    .foregroundColor(selectedIcon == icon ? .white : .primary)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // 参数摘要卡片
                VStack(alignment: .leading, spacing: 3) {
                    Text("包含的关键参数：")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    Text("分辨率: \(currentConfig.maxSize == 0 ? "原始" : "\(currentConfig.maxSize)P") | 码率: \(currentConfig.bitRateMbps)M | 帧率: \(currentConfig.maxFps == 0 ? "不限" : "\(currentConfig.maxFps)FPS") | 编码: \(currentConfig.videoCodec.uppercased()) | 息屏: \(currentConfig.turnScreenOff ? "开启" : "关闭")")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(0.04))
                .cornerRadius(6)
            }
            
            HStack {
                Button("取消") { dismiss() }
                    .buttonStyle(.bordered)
                
                Spacer()
                
                Button("保存为新预设") {
                    PresetManager.shared.saveCustomPreset(
                        title: presetTitle,
                        subtitle: presetSubtitle,
                        iconName: selectedIcon,
                        config: currentConfig
                    )
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(presetTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .frame(width: 440)
    }
}
