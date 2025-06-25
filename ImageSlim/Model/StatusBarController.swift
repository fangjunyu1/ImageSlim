import AppKit
import SwiftUI

class StatusBarController:ObservableObject {
    private var statusItem: NSStatusItem!
    
    init() {
        // 创建系统菜单栏图标
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(named: "templateIcon")
        }
        
        // 创建菜单
        let menu = NSMenu()
        
        let openItem = NSMenuItem(title: "打开 App", action: #selector(openApp), keyEquivalent: "o")
        openItem.target = self
        menu.addItem(openItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "退出", action: #selector(NSApp.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        let hideItem = NSMenuItem(title: "隐藏状态栏", action: #selector(removeStatusItem), keyEquivalent: "h")
        hideItem.target = self
        menu.addItem(hideItem)
        
        statusItem.menu = menu
        
    }
    
    @objc func openApp() {
        print("打开 App")
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func removeStatusItem() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }
}

