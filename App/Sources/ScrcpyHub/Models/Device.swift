import Foundation

public enum DeviceState: String, Codable {
    case device = "在线"
    case unauthorized = "未授权调试"
    case offline = "离线"
    case recovery = "恢复模式"
    case unknown = "未知状态"
    
    public var isUsable: Bool {
        self == .device
    }
}

public enum ConnectionType: String, Codable {
    case usb = "USB"
    case wifi = "Wi-Fi (无线)"
    
    public var iconName: String {
        switch self {
        case .usb:
            return "cable.connector.horizontal"
        case .wifi:
            return "wifi"
        }
    }
}

public struct Device: Identifiable, Hashable, Equatable {
    public var id: String { serial }
    public let serial: String
    public var model: String
    public var product: String
    public var deviceName: String
    public var state: DeviceState
    public var connectionType: ConnectionType
    public var batteryLevel: Int?
    public var isCharging: Bool?
    public var resolution: String?
    public var isMirroring: Bool = false
    public var marketName: String? = nil
    
    public init(
        serial: String,
        model: String = "Android 设备",
        product: String = "",
        deviceName: String = "",
        state: DeviceState = .device,
        connectionType: ConnectionType = .usb,
        batteryLevel: Int? = nil,
        isCharging: Bool? = nil,
        resolution: String? = nil,
        isMirroring: Bool = false,
        marketName: String? = nil
    ) {
        self.serial = serial
        self.model = model
        self.product = product
        self.deviceName = deviceName
        self.state = state
        self.connectionType = connectionType
        self.batteryLevel = batteryLevel
        self.isCharging = isCharging
        self.resolution = resolution
        self.isMirroring = isMirroring
        self.marketName = marketName
    }
    
    public var displayName: String {
        if let market = marketName, !market.isEmpty {
            return market.replacingOccurrences(of: "_", with: " ")
        }
        if !model.isEmpty && model != "unknown" && model != "Android 设备" {
            return model.replacingOccurrences(of: "_", with: " ")
        }
        if !deviceName.isEmpty {
            return deviceName
        }
        return serial
    }
}
