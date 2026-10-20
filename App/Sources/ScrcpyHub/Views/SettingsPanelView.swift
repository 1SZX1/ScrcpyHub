import SwiftUI

public struct SettingsPanelView: View {
    @ObservedObject private var langManager = LanguageManager.shared
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
                    Text(t("quick_presets"))
                        .font(.headline)
                    
                    Spacer()
                    
                    // 保存为自定义预设
                    Button(action: { isShowingSavePresetSheet = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text(t("save_as_preset"))
                        }
                        .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help(t("save_as_preset_help"))
                    
                    // 保存为全局默认配置
                    Button(action: {
                        config.saveAsDefault()
                        showToast(t("toast_saved_default"))
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "pin.fill")
                            Text(t("set_as_default"))
                        }
                        .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help(t("set_as_default_help"))
                    
                    // 更多设置（恢复出厂）
                    Menu {
                        Button(t("restore_factory_default")) {
                            config = ScrcpyConfig.resetToFactoryDefault()
                            showToast(t("toast_restored_factory"))
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .help(t("config_options"))
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
                Text(t("tab_video_perf")).tag(0)
                Text(t("tab_run_display")).tag(1)
                Text(t("tab_audio_record")).tag(2)
                Text(t("tab_advanced_cli")).tag(3)
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
                Label(t("max_size_limit"), systemImage: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")
                    .frame(width: 160, alignment: .leading)
                
                Picker("", selection: $config.maxSize) {
                    Text(t("res_native")).tag(0)
                    Text(t("res_720")).tag(720)
                    Text(t("res_1080")).tag(1080)
                    Text(t("res_1440")).tag(1440)
                    Text(t("res_1920")).tag(1920)
                }
                .pickerStyle(.menu)
            }
            
            // 码率调节
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label(t("video_bitrate"), systemImage: "gauge.with.needle")
                        .frame(width: 160, alignment: .leading)
                    
                    Slider(value: Binding(
                        get: { Double(config.bitRateMbps) },
                        set: { config.bitRateMbps = Int($0) }
                    ), in: 2...40, step: 2)
                    
                    Text("\(config.bitRateMbps) Mbps")
                        .font(.system(size: 12, design: .monospaced))
                        .frame(width: 65, alignment: .trailing)
                }
                Text(t("bitrate_hint"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.leading, 164)
            }
            
            // 帧率上限
            HStack {
                Label(t("max_fps_limit"), systemImage: "timer")
                    .frame(width: 160, alignment: .leading)
                
                Picker("", selection: $config.maxFps) {
                    Text(t("fps_unlimited")).tag(0)
                    Text(t("fps_30")).tag(30)
                    Text(t("fps_60")).tag(60)
                    Text(t("fps_90")).tag(90)
                    Text(t("fps_120")).tag(120)
                }
                .pickerStyle(.menu)
            }
            
            // 编解码器
            HStack {
                Label(t("video_codec"), systemImage: "film")
                    .frame(width: 160, alignment: .leading)
                
                Picker("", selection: $config.videoCodec) {
                    Text(t("codec_h264")).tag("h264")
                    Text(t("codec_h265")).tag("h265")
                    Text(t("codec_av1")).tag("av1")
                }
                .pickerStyle(.menu)
            }
            
            // 缓冲延时
            HStack {
                Label(t("display_buffer"), systemImage: "water.waves")
                    .frame(width: 160, alignment: .leading)
                
                Picker("", selection: $config.displayBufferMs) {
                    Text(t("buffer_0")).tag(0)
                    Text(t("buffer_20")).tag(20)
                    Text(t("buffer_50")).tag(50)
                    Text(t("buffer_100")).tag(100)
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
                    Text(t("turn_screen_off"))
                        .font(.system(size: 13, weight: .medium))
                    Text(t("turn_screen_off_desc"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Toggle(isOn: $config.stayAwake) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(t("stay_awake"))
                        .font(.system(size: 13, weight: .medium))
                    Text(t("stay_awake_desc"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Toggle(isOn: $config.alwaysOnTop) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(t("always_on_top"))
                        .font(.system(size: 13, weight: .medium))
                    Text(t("always_on_top_desc"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Toggle(isOn: $config.fullscreen) {
                Text(t("fullscreen"))
                    .font(.system(size: 13, weight: .medium))
            }
            
            Toggle(isOn: $config.showTouches) {
                Text(t("show_touches"))
                    .font(.system(size: 13, weight: .medium))
            }
            
            Toggle(isOn: $config.readOnly) {
                Text(t("read_only"))
                    .font(.system(size: 13, weight: .medium))
            }
            
            HStack {
                Label(t("display_orientation"), systemImage: "rotate.right")
                    .frame(width: 160, alignment: .leading)
                
                Picker("", selection: $config.displayOrientation) {
                    Text(t("orient_sensor")).tag(0)
                    Text(t("orient_90")).tag(90)
                    Text(t("orient_180")).tag(180)
                    Text(t("orient_270")).tag(270)
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
                    Text(t("audio_sync"))
                        .font(.system(size: 13, weight: .medium))
                    Text(t("audio_sync_desc"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if config.audioEnabled {
                HStack {
                    Label(t("audio_codec"), systemImage: "waveform")
                        .frame(width: 160, alignment: .leading)
                    
                    Picker("", selection: $config.audioCodec) {
                        Text(t("codec_opus")).tag("opus")
                        Text(t("codec_aac")).tag("aac")
                        Text(t("codec_raw")).tag("raw")
                    }
                    .pickerStyle(.menu)
                }
            }
            
            Divider()
            
            // 录屏设置
            Toggle(isOn: $config.recordEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(t("record_enabled"))
                        .font(.system(size: 13, weight: .medium))
                    Text(t("record_desc"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if config.recordEnabled {
                HStack {
                    TextField(t("record_path_placeholder"), text: $config.recordPath)
                        .textFieldStyle(.roundedBorder)
                    
                    Button(t("choose_location")) {
                        selectSaveRecordPath()
                    }
                }
            }
        }
    }
    
    // MARK: - 高级与指令
    private var advancedSettingsView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(t("custom_cli_flags"))
                .font(.system(size: 13, weight: .semibold))
            
            TextField(t("custom_flags_placeholder"), text: $config.customArgs)
                .textFieldStyle(.roundedBorder)
            
            Text(t("cmd_preview"))
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
    @ObservedObject private var langManager = LanguageManager.shared
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
                    
                    Text(preset.localizedTitle)
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
                        .help(t("delete_custom_preset"))
                    }
                }
                
                Text(preset.localizedSubtitle)
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
                    Label(t("delete_preset"), systemImage: "trash")
                }
            }
        }
    }
}

struct SavePresetSheet: View {
    @ObservedObject private var langManager = LanguageManager.shared
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
                Text(t("save_preset_title"))
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
                    Text(t("preset_name_label"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField(t("preset_name_placeholder"), text: $presetTitle)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(t("preset_desc_label"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField(t("preset_desc_placeholder"), text: $presetSubtitle)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(t("preset_icon_label"))
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
                    Text(t("key_parameters_summary"))
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
                Button(t("cancel")) { dismiss() }
                    .buttonStyle(.bordered)
                
                Spacer()
                
                Button(t("save_as_new_preset")) {
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
