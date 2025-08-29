//
//  WindowManager.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/6/30.
//

import AppKit
import SwiftUI

class StatusBarController:ObservableObject {
    private var statusItem: NSStatusItem?
    
    init() {
        // 创建系统菜单栏图标
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        // 添加菜单栏菜单
        if let status = statusItem {
            if let button = status.button {
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
            
            status.menu = menu
        } else {
            print("没有 statusItem 状态栏")
        }
        
    }
    
    @objc func openApp() {
        if let window = WindowManager.shared.mainWindow {
            //NSApp.activate(ignoringOtherApps: true) 
            window.makeKeyAndOrderFront(nil)
        } else {
            print("没有窗口")
        }
    }
    
    func removeFromStatusBar() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }
}
