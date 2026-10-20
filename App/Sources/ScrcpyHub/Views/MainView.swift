import SwiftUI

public struct MainView: View {
    @ObservedObject private var langManager = LanguageManager.shared
    @StateObject private var adbService = ADBService.shared
    @StateObject private var processManager = ProcessManager.shared
    
    @State private var selectedSerial: String? = nil
    @State private var config = ScrcpyConfig.loadDefault()
    @State private var isShowingWirelessSheet: Bool = false
    @State private var isShowingLogSheet: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            // 左侧：设备列表与连接中心
            VStack(spacing: 0) {
                // 顶部工具栏
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t("connected_devices"))
                            .font(.system(size: 13, weight: .bold))
                        Text("\(adbService.devices.count) \(t("devices_online_count"))")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // 无线连接向导
                    Button(action: { isShowingWirelessSheet = true }) {
                        Image(systemName: "wifi.badge.plus")
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.plain)
                    .help(t("wireless_adb_wizard"))
                    
                    // 手动刷新
                    Button(action: { adbService.refreshDevices(isManual: true) }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .rotationEffect(.degrees(adbService.isRefreshing ? 360 : 0))
                            .animation(adbService.isRefreshing ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: adbService.isRefreshing)
                    }
                    .buttonStyle(.plain)
                    .help(t("refresh_device_list"))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.primary.opacity(0.03))
                
                Divider()
                
                // 设备卡片滚动列表
                if adbService.devices.isEmpty {
                    emptyDeviceView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(adbService.devices) { dev in
                                DeviceCardView(
                                    device: dev,
                                    isSelected: selectedSerial == dev.serial,
                                    onSelect: {
                                        selectedSerial = dev.serial
                                    },
                                    onToggleMirror: {
                                        toggleMirroring(for: dev)
                                    }
                                )
                            }
                            
                            // 即使已有设备连接，列表底部常驻添加无线设备卡片
                            Button(action: { isShowingWirelessSheet = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "wifi.badge.plus")
                                        .font(.system(size: 13, weight: .medium))
                                    Text(t("connect_new_wireless"))
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(.accentColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                        .foregroundColor(Color.accentColor.opacity(0.4))
                                )
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.accentColor.opacity(0.04))
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                        }
                        .padding(10)
                    }
                }
                
                Divider()
                
                // 侧边栏底部：快捷状态与停止所有
                HStack {
                    if !processManager.activeSerials.isEmpty {
                        Button(role: .destructive, action: {
                            processManager.stopAll()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "stop.circle.fill")
                                Text("\(t("stop_all")) (\(processManager.activeSerials.count))")
                            }
                            .font(.system(size: 11))
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    } else {
                        HStack(spacing: 4) {
                            Circle().fill(Color.green).frame(width: 6, height: 6)
                            Text(t("adb_daemon_running"))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: { isShowingLogSheet = true }) {
                        HStack(spacing: 3) {
                            Image(systemName: "terminal")
                            Text(t("running_logs"))
                        }
                        .font(.system(size: 10))
                    }
                    .buttonStyle(.link)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.02))
            }
            .navigationSplitViewColumnWidth(min: 280, ideal: 300, max: 360)
        } detail: {
            // 右侧：当前选中设备的配置与启动主控台
            VStack(spacing: 0) {
                // 顶部状态栏
                HStack {
                    if let dev = currentDevice {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(dev.displayName)
                                    .font(.system(size: 16, weight: .bold))
                                Text(dev.serial)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            Text(dev.isMirroring ? t("status_mirroring") : t("status_ready"))
                                .font(.system(size: 11))
                                .foregroundColor(dev.isMirroring ? .green : .secondary)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(t("global_default_config"))
                                .font(.system(size: 16, weight: .bold))
                            Text(t("select_device_hint"))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if let dev = currentDevice, dev.isMirroring {
                        Button(action: {
                            FloatingToolbarWindowManager.shared.openToolbar(for: dev)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "dock.rectangle")
                                Text(t("show_floating_toolbar"))
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    // 🌐 多语言切换原生下拉选择器（与设置面板中的 Picker 完全一致的原生样式）
                    HStack(spacing: 4) {
                        Image(systemName: "globe")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $langManager.selectedLanguage) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.displayName).tag(lang)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 110)
                    }
                    .help(t("language"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.primary.opacity(0.03))
                
                Divider()
                
                // 配置主面板
                SettingsPanelView(config: $config, activeDevice: currentDevice)
                
                Divider()
                
                // 底部大按钮操作区
                HStack {
                    if let dev = currentDevice {
                        Button(action: {
                            toggleMirroring(for: dev)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: dev.isMirroring ? "stop.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 16))
                                Text(dev.isMirroring ? t("stop_mirroring") : t("start_mirroring"))
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(dev.isMirroring ? .red : .accentColor)
                        .disabled(!dev.state.isUsable)
                    } else {
                        Text(t("please_select_device"))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                    }
                }
                .padding(14)
                .background(Color.primary.opacity(0.02))
            }
        }
        .sheet(isPresented: $isShowingWirelessSheet) {
            WirelessConnectSheet()
        }
        .sheet(isPresented: $isShowingLogSheet) {
            LogViewerSheet(processManager: processManager)
        }
        .onAppear {
            if selectedSerial == nil, let first = adbService.devices.first {
                selectedSerial = first.serial
            }
        }
        .onChange(of: adbService.devices) { newDevices in
            if selectedSerial == nil || !newDevices.contains(where: { $0.serial == selectedSerial }) {
                selectedSerial = newDevices.first?.serial
            }
        }
    }
    
    private var currentDevice: Device? {
        guard let s = selectedSerial else { return nil }
        return adbService.devices.first(where: { $0.serial == s })
    }
    
    private func toggleMirroring(for device: Device) {
        if device.isMirroring {
            processManager.stopMirroring(serial: device.serial)
        } else {
            processManager.startMirroring(device: device, config: config)
        }
    }
    
    private var emptyDeviceView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "cable.connector.slash")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            
            Text(t("no_device_detected"))
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(t("troubleshooting_title"))
                    .font(.caption)
                    .fontWeight(.bold)
                Text(t("troubleshooting_1"))
                    .font(.caption2)
                Text(t("troubleshooting_2"))
                    .font(.caption2)
                Text(t("troubleshooting_3"))
                    .font(.caption2)
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 20)
            
            Button(t("wireless_connect_action")) {
                isShowingWirelessSheet = true
            }
            .buttonStyle(.bordered)
            .padding(.top, 4)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct LogViewerSheet: View {
    @ObservedObject var processManager: ProcessManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "terminal")
                Text("Scrcpy 实时运行日志")
                    .font(.headline)
                Spacer()
                Button("关闭") { dismiss() }
            }
            .padding([.top, .horizontal], 16)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    if processManager.sessionLogs.isEmpty {
                        Text("暂无运行日志")
                            .foregroundColor(.secondary)
                            .font(.system(size: 11, design: .monospaced))
                    } else {
                        ForEach(Array(processManager.sessionLogs.keys), id: \.self) { serial in
                            Text("=== 设备 [\(serial)] ===")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.accentColor)
                            
                            ForEach(processManager.sessionLogs[serial] ?? [], id: \.self) { line in
                                Text(line)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.black.opacity(0.04))
            .cornerRadius(8)
            .padding([.bottom, .horizontal], 16)
        }
        .frame(width: 580, height: 420)
    }
}
