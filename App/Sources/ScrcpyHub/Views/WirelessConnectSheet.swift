import SwiftUI
import AppKit

public struct WirelessConnectSheet: View {
    @ObservedObject private var langManager = LanguageManager.shared
    @Environment(\.dismiss) private var dismiss
    
    // 默认展示 6 位配对码配对
    @State private var selectedTab: Int = 0
    
    // 手动配对码状态
    @State private var pairAddress: String = ""
    @State private var pairPort: String = ""
    @State private var pairCode: String = ""
    @State private var isPairConnecting: Bool = false
    @State private var pairStatus: String? = nil
    @State private var isPairSuccess: Bool = false
    
    // IP 直连状态
    @State private var directAddress: String = ""
    @State private var directPort: String = "5555"
    @State private var isDirectConnecting: Bool = false
    @State private var directStatus: String? = nil
    @State private var isDirectSuccess: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 16) {
            // 头部标题与关闭按钮
            HStack {
                Image(systemName: "wifi")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text(t("wireless_adb_wizard_title"))
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
            
            // 模式切换
            Picker("", selection: $selectedTab) {
                Text(t("tab_pairing_code")).tag(0)
                Text(t("tab_direct_ip")).tag(1)
            }
            .pickerStyle(.segmented)
            
            // 内容区域
            Group {
                if selectedTab == 0 {
                    manualPairView
                } else {
                    directConnectView
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(width: 480, height: 300)
    }
    
    // MARK: - 6 位配对码配对视图 (Android 11+)
    private var manualPairView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(t("pairing_code_guide_title"))
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                TextField(t("pair_ip_placeholder"), text: $pairAddress)
                    .textFieldStyle(.roundedBorder)
                
                Text(":")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                TextField(t("port"), text: $pairPort)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
            }
            
            TextField(t("pairing_code_placeholder"), text: $pairCode)
                .textFieldStyle(.roundedBorder)
            
            Button(action: performPairConnect) {
                HStack {
                    if isPairConnecting {
                        ProgressView()
                            .scaleEffect(0.6)
                    } else {
                        Image(systemName: "bolt.fill")
                    }
                    Text(t("pair_and_connect_action"))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .disabled(isPairConnecting || pairAddress.trimmingCharacters(in: .whitespaces).isEmpty || pairPort.trimmingCharacters(in: .whitespaces).isEmpty || pairCode.trimmingCharacters(in: .whitespaces).isEmpty)
            
            if let status = pairStatus {
                HStack(spacing: 6) {
                    Image(systemName: isPairSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(isPairSuccess ? .green : .orange)
                    Text(status)
                        .font(.caption)
                        .foregroundColor(isPairSuccess ? .primary : .red)
                }
                .padding(.top, 2)
            }
        }
        .padding(.top, 4)
    }
    
    // MARK: - 局域网直连视图
    private var directConnectView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(t("direct_ip_guide_title"))
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                TextField(langManager.isChinese ? "例如: 192.168.31.142" : "e.g.: 192.168.31.142", text: $directAddress)
                    .textFieldStyle(.roundedBorder)
                
                Text(":")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                TextField("5555", text: $directPort)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
            }
            
            Button(action: performDirectConnect) {
                HStack {
                    if isDirectConnecting {
                        ProgressView()
                            .scaleEffect(0.6)
                    } else {
                        Image(systemName: "link")
                    }
                    Text(t("connect_now_action"))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .disabled(isDirectConnecting || directAddress.trimmingCharacters(in: .whitespaces).isEmpty)
            
            if let status = directStatus {
                HStack(spacing: 6) {
                    Image(systemName: isDirectSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(isDirectSuccess ? .green : .orange)
                    Text(status)
                        .font(.caption)
                        .foregroundColor(isDirectSuccess ? .primary : .red)
                }
                .padding(.top, 4)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - 局域网直连处理
    private func performDirectConnect() {
        let addr = "\(directAddress.trimmingCharacters(in: .whitespaces)):\(directPort.trimmingCharacters(in: .whitespaces))"
        isDirectConnecting = true
        directStatus = "\(t("connecting_to")) \(addr)..."
        isDirectSuccess = false
        
        Task {
            let res = await ADBService.shared.connectWireless(address: addr)
            await MainActor.run {
                isDirectConnecting = false
                switch res {
                case .success(let msg):
                    isDirectSuccess = true
                    directStatus = "\(t("connect_success"))\(msg)"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        dismiss()
                    }
                case .failure(let err):
                    isDirectSuccess = false
                    directStatus = err.localizedDescription
                }
            }
        }
    }
    
    // MARK: - 配对码配对处理
    private func performPairConnect() {
        let ip = pairAddress.trimmingCharacters(in: .whitespaces)
        let port = pairPort.trimmingCharacters(in: .whitespaces)
        let addr = "\(ip):\(port)"
        let code = pairCode.trimmingCharacters(in: .whitespaces)
        
        isPairConnecting = true
        pairStatus = "\(t("pairing_with")) \(addr)..."
        isPairSuccess = false
        
        Task {
            let res = await ADBService.shared.pairWireless(address: addr, code: code)
            await MainActor.run {
                switch res {
                case .success(let msg):
                    isPairSuccess = true
                    pairStatus = t("pair_success_connecting")
                    Task {
                        let services = await ADBService.shared.getMdnsServices()
                        var connAddr: String? = nil
                        if let conn = services.first(where: { $0.type.contains("connect") && $0.address.starts(with: ip) }) {
                            connAddr = conn.address
                        }
                        
                        if let target = connAddr {
                            _ = await ADBService.shared.connectWireless(address: target)
                        } else {
                            // 备用尝试：连接 5555 端口
                            _ = await ADBService.shared.connectWireless(address: "\(ip):5555")
                        }
                        
                        await MainActor.run {
                            isPairConnecting = false
                            pairStatus = "\(t("pair_success_joined"))\(msg)"
                            ADBService.shared.refreshDevices(isManual: true)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                dismiss()
                            }
                        }
                    }
                case .failure(let err):
                    isPairConnecting = false
                    isPairSuccess = false
                    pairStatus = "\(t("pair_failed"))\(err.localizedDescription)"
                }
            }
        }
    }
}
