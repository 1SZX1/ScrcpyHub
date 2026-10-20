import Foundation

public final class BinaryLocator {
    public static let shared = BinaryLocator()
    
    private init() {}
    
    /// 获取 adb 可执行文件路径
    public func adbPath() -> String {
        if let env = ProcessInfo.processInfo.environment["ADB_PATH"], FileManager.default.isExecutableFile(atPath: env) {
            return env
        }
        return findBinary(named: "adb")
    }
    
    /// 获取 scrcpy 可执行文件路径
    public func scrcpyPath() -> String {
        if let env = ProcessInfo.processInfo.environment["SCRCPY_PATH"], FileManager.default.isExecutableFile(atPath: env) {
            return env
        }
        return findBinary(named: "scrcpy")
    }
    
    /// 获取 scrcpy-server jar 文件路径
    public func scrcpyServerPath() -> String? {
        if let env = ProcessInfo.processInfo.environment["SCRCPY_SERVER_PATH"], FileManager.default.fileExists(atPath: env) {
            return env
        }
        let serverNames = ["scrcpy-server", "scrcpy-server.jar"]
        for name in serverNames {
            let path = findResource(named: name)
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return nil
    }
    
    private func findBinary(named name: String) -> String {
        // 1. App Bundle Resources/bin/<name>
        if let bundleBin = Bundle.main.resourceURL?.appendingPathComponent("bin/\(name)").path,
           FileManager.default.isExecutableFile(atPath: bundleBin) {
            return bundleBin
        }
        
        // 2. App Bundle Resources/<name>
        if let bundleRes = Bundle.main.resourceURL?.appendingPathComponent(name).path,
           FileManager.default.isExecutableFile(atPath: bundleRes) {
            return bundleRes
        }
        
        // 3. 与 .app 同级 bin 目录或同级文件
        let appDir = Bundle.main.bundleURL.deletingLastPathComponent()
        let appBin = appDir.appendingPathComponent("bin/\(name)").path
        if FileManager.default.isExecutableFile(atPath: appBin) {
            return appBin
        }
        let appAdjacent = appDir.appendingPathComponent(name).path
        if FileManager.default.isExecutableFile(atPath: appAdjacent) {
            return appAdjacent
        }
        
        // 4. 当前工作目录下的 bin/ 或当前目录
        let currentUrl = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let candidatePaths = [
            currentUrl.appendingPathComponent("bin/\(name)").path,
            currentUrl.appendingPathComponent("../bin/\(name)").path,
            currentUrl.appendingPathComponent("../../bin/\(name)").path,
            currentUrl.appendingPathComponent(name).path,
            currentUrl.appendingPathComponent("../\(name)").path
        ]
        for p in candidatePaths {
            if FileManager.default.isExecutableFile(atPath: p) {
                return URL(fileURLWithPath: p).resolvingSymlinksInPath().path
            }
        }
        
        // 5. 系统 Homebrew 与环境路径
        let commonPaths = [
            "/opt/homebrew/bin/\(name)",
            "/usr/local/bin/\(name)",
            "/usr/bin/\(name)"
        ]
        for p in commonPaths {
            if FileManager.default.isExecutableFile(atPath: p) {
                return p
            }
        }
        
        return name
    }
    
    private func findResource(named name: String) -> String {
        if let bundleRes = Bundle.main.resourceURL?.appendingPathComponent(name).path,
           FileManager.default.fileExists(atPath: bundleRes) {
            return bundleRes
        }
        if let bundleBin = Bundle.main.resourceURL?.appendingPathComponent("bin/\(name)").path,
           FileManager.default.fileExists(atPath: bundleBin) {
            return bundleBin
        }
        
        let appDir = Bundle.main.bundleURL.deletingLastPathComponent()
        let appBin = appDir.appendingPathComponent("bin/\(name)").path
        if FileManager.default.fileExists(atPath: appBin) {
            return appBin
        }
        let appAdjacent = appDir.appendingPathComponent(name).path
        if FileManager.default.fileExists(atPath: appAdjacent) {
            return appAdjacent
        }
        
        let currentUrl = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let candidatePaths = [
            currentUrl.appendingPathComponent("bin/\(name)").path,
            currentUrl.appendingPathComponent("../bin/\(name)").path,
            currentUrl.appendingPathComponent("../../bin/\(name)").path,
            currentUrl.appendingPathComponent(name).path,
            currentUrl.appendingPathComponent("../\(name)").path
        ]
        for p in candidatePaths {
            if FileManager.default.fileExists(atPath: p) {
                return URL(fileURLWithPath: p).resolvingSymlinksInPath().path
            }
        }
        
        return name
    }
}
