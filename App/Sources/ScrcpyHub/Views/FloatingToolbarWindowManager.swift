import AppKit
import SwiftUI

@MainActor
public final class FloatingToolbarWindowManager {
    public static let shared = FloatingToolbarWindowManager()
    
    private var panels: [String: NSPanel] = [:]
    
    private init() {}
    
    public func openToolbar(for device: Device) {
        let serial = device.serial
        if let existing = panels[serial] {
            existing.orderFront(nil)
            return
        }
        
        let panel = NSPanel(
            contentRect: NSRect(x: 100, y: 100, width: 320, height: 110),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovable = true
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        
        let hostingView = NSHostingView(rootView: FloatingToolbarView(device: device))
        panel.contentView = hostingView
        
        // 自动居中偏下摆放
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.midX - 160
            let y = screenRect.minY + 60
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        panel.orderFront(nil)
        panels[serial] = panel
    }
    
    public func closeToolbar(for serial: String) {
        if let panel = panels[serial] {
            panel.close()
            panels.removeValue(forKey: serial)
        }
    }
    
    public func closeAll() {
        for (_, panel) in panels {
            panel.close()
        }
        panels.removeAll()
    }
}
