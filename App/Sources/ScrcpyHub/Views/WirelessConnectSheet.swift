import SwiftUI
import AppKit

public struct WirelessConnectSheet: View {
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
                Text("无线 ADB 连接向导")
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
                Text("🔢 6 位配对码 (Android 11+)").tag(0)
                Text("⚡️ 局域网直连 (默认 5555)").tag(1)
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
        .frame(width: 460, height: 290)
    }
    
    // MARK: - 6 位配对码配对视图 (Android 11+)
    private var manualPairView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("在手机【开发者选项 -> 无线调试 -> 使用配对码配对设备】弹窗中查看：")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                TextField("配对 IP (例如 192.168.31.142)", text: $pairAddress)
                    .textFieldStyle(.roundedBorder)
                
                Text(":")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                TextField("端口", text: $pairPort)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
            }
            
            TextField("6 位配对验证码 (例如 849201)", text: $pairCode)
                .textFieldStyle(.roundedBorder)
            
            Button(action: performPairConnect) {
                HStack {
                    if isPairConnecting {
                        ProgressView()
                            .scaleEffect(0.6)
                    } else {
                        Image(systemName: "bolt.fill")
                    }
                    Text("立即配对并连接")
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
            Text("输入手机局域网 IP 地址及端口（需先在手机端通过有线或终端开启 5555 端口）：")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                TextField("例如: 192.168.31.142", text: $directAddress)
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
                    Text("立即连接")
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
        directStatus = "正在连接 \(addr)..."
        isDirectSuccess = false
        
        Task {
            let res = await ADBService.shared.connectWireless(address: addr)
            await MainActor.run {
                isDirectConnecting = false
                switch res {
                case .success(let msg):
                    isDirectSuccess = true
                    directStatus = "连接成功！\(msg)"
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
        pairStatus = "正在向 \(addr) 发起安全配对..."
        isPairSuccess = false
        
        Task {
            let res = await ADBService.shared.pairWireless(address: addr, code: code)
            await MainActor.run {
                switch res {
                case .success(let msg):
                    isPairSuccess = true
                    pairStatus = "配对成功！正在建立调试连接..."
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
                            pairStatus = "已成功加入设备池！\(msg)"
                            ADBService.shared.refreshDevices(isManual: true)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                dismiss()
                            }
                        }
                    }
                case .failure(let err):
                    isPairConnecting = false
                    isPairSuccess = false
                    pairStatus = "配对失败: \(err.localizedDescription)"
                }
            }
        }
    }
}
