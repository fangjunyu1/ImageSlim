//
//  AppDelegate.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/6/24.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()
        
        let contentView = ContentView()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 550),
            styleMask: [.titled, .closable, .miniaturizable, .resizable], // 可以调大小
            backing: .buffered,
            defer: false)
        
        window.center()
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: contentView)
        
        window.makeKeyAndOrderFront(nil)
        
        WindowManager.shared.mainWindow = window
        print("window完成初始化")
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        print("点击Dock栏，显示window")
        if !flag {
            WindowManager.shared.mainWindow?.makeKeyAndOrderFront(nil)
        }
        return true
    }
}
