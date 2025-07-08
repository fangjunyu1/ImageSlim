//
//  WindowManager.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/6/30.
//

import AppKit
import SwiftUI

class StatusBarController:ObservableObject {
    private var statusItem: NSStatusItem!
    
    init() {
        // 创建系统菜单栏图标
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(named: "templateIcon")
            button.toolTip = Bundle.main.appName
        }
        
        // 创建菜单
        let menu = NSMenu()
        
        let openTitle = NSLocalizedString("Open", comment: "退出应用程序的菜单项标题")
        let openItem = NSMenuItem(title: openTitle, action: #selector(openApp), keyEquivalent: "o")
        openItem.target = self
        
        menu.addItem(openItem)
        
        let separator = NSMenuItem.separator()
        menu.addItem(separator)
        
        let quitTitle = NSLocalizedString("Quit", comment: "退出应用程序的菜单项标题")
        let quitItem = NSMenuItem(title: quitTitle, action: #selector(NSApp.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        
    }
    
    @objc func openApp() {
        if let window = WindowManager.shared.mainWindow {
            window.makeKeyAndOrderFront(nil)
        } else {
            print("没有窗口")
        }
    }
}
