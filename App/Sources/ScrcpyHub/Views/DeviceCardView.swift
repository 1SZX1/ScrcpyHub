import SwiftUI

public struct DeviceCardView: View {
    @ObservedObject private var langManager = LanguageManager.shared
    public let device: Device
    public let isSelected: Bool
    public let onSelect: () -> Void
    public let onToggleMirror: () -> Void
    
    @State private var isSwitchingToWireless: Bool = false
    @State private var wirelessMessage: String? = nil
    
    public init(
        device: Device,
        isSelected: Bool,
        onSelect: @escaping () -> Void,
        onToggleMirror: @escaping () -> Void
    ) {
        self.device = device
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.onToggleMirror = onToggleMirror
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 头部：连接类型、名称、状态与投屏指示
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(stateColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: device.connectionType == .usb ? "cable.connector" : "wifi")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(stateColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(device.displayName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Circle()
                            .fill(stateColor)
                            .frame(width: 7, height: 7)
                    }
                    
                    Text(device.serial)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if device.isMirroring {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text(t("mirroring_badge"))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.12))
                    .cornerRadius(6)
                }
            }
            
            // 中部：关键指标徽标（电量、分辨率、状态）
            HStack(spacing: 8) {
                // 电量
                if let battery = device.batteryLevel {
                    Label {
                        Text("\(battery)%" + (device.isCharging == true ? " (\(t("battery_charging")))" : ""))
                            .font(.system(size: 10))
                    } icon: {
                        Image(systemName: device.isCharging == true ? "bolt.fill" : "battery.75")
                            .font(.system(size: 10))
                            .foregroundColor(device.isCharging == true ? .green : .secondary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(4)
                }
                
                // 分辨率
                if let res = device.resolution {
                    Label {
                        Text(res)
                            .font(.system(size: 10))
                    } icon: {
                        Image(systemName: "rectangle.inset.filled")
                            .font(.system(size: 9))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(4)
                }
                
                // 状态文本（如未授权等特殊状态）
                if device.state != .device {
                    Text(device.state.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .foregroundColor(.secondary)
            
            Divider().opacity(0.4)
            
            // 底部操作按钮
            HStack(spacing: 8) {
                // 启动 / 停止投屏
                Button(action: onToggleMirror) {
                    HStack(spacing: 4) {
                        Image(systemName: device.isMirroring ? "stop.fill" : "play.fill")
                        Text(device.isMirroring ? t("stop_mirroring") : t("start_mirroring"))
                    }
                    .font(.system(size: 11, weight: .medium))
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(device.isMirroring ? .red : .accentColor)
                .disabled(!device.state.isUsable)
                
                // 如果是 USB 设备，支持一键切换为无线 ADB
                if device.connectionType == .usb && device.state.isUsable {
                    Button(action: switchToWireless) {
                        HStack(spacing: 4) {
                            if isSwitchingToWireless {
                                ProgressView()
                                    .scaleEffect(0.5)
                            } else {
                                Image(systemName: "wifi")
                            }
                            Text(t("one_click_wireless"))
                        }
                        .font(.system(size: 11))
                    }
                    .buttonStyle(.bordered)
                    .disabled(isSwitchingToWireless)
                    .help(t("one_click_wireless"))
                }
                
                // 控制条唤起
                if device.isMirroring {
                    Button(action: {
                        FloatingToolbarWindowManager.shared.openToolbar(for: device)
                    }) {
                        Image(systemName: "dock.rectangle")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.bordered)
                    .help(t("show_floating_toolbar"))
                }
            }
            
            if let msg = wirelessMessage {
                Text(msg)
                    .font(.system(size: 9))
                    .foregroundColor(.accentColor)
            }
        }
        .padding(12)
        .background(isSelected ? Color.accentColor.opacity(0.08) : Color.primary.opacity(0.03))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor : Color.primary.opacity(0.1), lineWidth: isSelected ? 1.5 : 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
    
    private var stateColor: Color {
        switch device.state {
        case .device: return .green
        case .unauthorized: return .orange
        case .offline: return .red
        default: return .gray
        }
    }
    
    private func switchToWireless() {
        isSwitchingToWireless = true
        wirelessMessage = "正在配置无线 ADB 并直连..."
        Task {
            let res = await ADBService.shared.enableWirelessAndConnect(serial: device.serial)
            await MainActor.run {
                isSwitchingToWireless = false
                switch res {
                case .success(let target):
                    wirelessMessage = "已连接无线设备: \(target)"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        wirelessMessage = nil
                    }
                case .failure(let err):
                    wirelessMessage = "转无线失败: \(err.localizedDescription)"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        wirelessMessage = nil
                    }
                }
            }
        }
    }
}
