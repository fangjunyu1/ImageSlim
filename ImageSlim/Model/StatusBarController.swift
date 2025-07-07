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
            button.toolTip = Bundle.main.displayName
        }
        
        // 创建菜单
        let menu = NSMenu()
        
        let quitItem = NSMenuItem(title: "退出", action: #selector(NSApp.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        
    }
}
