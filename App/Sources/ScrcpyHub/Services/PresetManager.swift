import Foundation
import Combine

@MainActor
public final class PresetManager: ObservableObject {
    public static let shared = PresetManager()
    
    @Published public var customPresets: [PresetProfile] = []
    
    private let userDefaultsKey = "ScrcpyHub_CustomPresets_v1"
    
    private init() {
        loadCustomPresets()
    }
    
    public var allPresets: [PresetProfile] {
        PresetProfile.builtInPresets + customPresets
    }
    
    public func saveCustomPreset(title: String, subtitle: String, iconName: String, config: ScrcpyConfig) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = trimmedTitle.isEmpty ? "我的自定义预设" : trimmedTitle
        
        var finalSubtitle = subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if finalSubtitle.isEmpty {
            let resText = config.maxSize == 0 ? "原始" : "\(config.maxSize)P"
            let fpsText = config.maxFps == 0 ? "不限帧率" : "\(config.maxFps)FPS"
            finalSubtitle = "\(resText) · \(config.bitRateMbps)M · \(fpsText)"
        }
        
        let preset = PresetProfile(
            id: UUID().uuidString,
            title: finalTitle,
            subtitle: finalSubtitle,
            iconName: iconName.isEmpty ? "star.fill" : iconName,
            config: config,
            isCustom: true
        )
        customPresets.append(preset)
        persist()
    }
    
    public func deletePreset(id: String) {
        customPresets.removeAll { $0.id == id }
        persist()
    }
    
    private func persist() {
        if let data = try? JSONEncoder().encode(customPresets) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    private func loadCustomPresets() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let list = try? JSONDecoder().decode([PresetProfile].self, from: data) {
            self.customPresets = list
        }
    }
}
