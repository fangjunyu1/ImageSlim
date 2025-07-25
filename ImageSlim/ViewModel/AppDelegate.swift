//
//  AppDelegate.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/6/24.
//

import AppKit
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        // 初始化键盘监听事件
        KeyboardMonitor.shared.startMonitoring()
        
        // 获取内购信息的动态数据
        Task {
            await IAPManager.shared.loadProduct()
            await IAPManager.shared.handleTransactions()
        }
        
        
        // 根据设置中的菜单栏选项，创建菜单栏
        if AppStorage.shared.displayMenuBarIcon {
            statusBarController = StatusBarController()
        }
        
        // 监听 displayMenuBarIcon 的变化
        AppStorage.shared.$displayMenuBarIcon
            .receive(on: RunLoop.main)
            .sink { [weak self] showIcon in
                guard let self = self else { return }
                if showIcon {
                    if self.statusBarController == nil {
                        self.statusBarController = StatusBarController()
                    }
                } else {
                    self.statusBarController?.removeFromStatusBar()
                    self.statusBarController = nil
                }
            }
            .store(in: &cancellables)
        
        let contentVC = NSHostingController(rootView: ContentView())
        let workspaceVC = NSHostingController(rootView: WorkspaceView())
        
        // 创建 NSSplitViewController 并添加子项
        let splitVC = NSSplitViewController()
        
        // 创建 NSSplitViewItem
        let sidebarItem = NSSplitViewItem(sidebarWithViewController: contentVC)
        sidebarItem.canCollapse = false
        let viewItem = NSSplitViewItem(viewController: workspaceVC)
        
        // 添加到控制器
        splitVC.addSplitViewItem(sidebarItem)
        splitVC.addSplitViewItem(viewItem)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 550),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView], // 可以调大小
            backing: .buffered,
            defer: false)
        window.center()
        window.isReleasedWhenClosed = false
        window.contentViewController = splitVC
        window.minSize = NSSize(width: 600, height: 400)
        window.maxSize = NSSize(width: 1200, height: 800)
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
    
    func applicationWillTerminate(_ notification: Notification) {
        print("应用即将退出，清除状态栏图标")
        statusBarController?.removeFromStatusBar()
        statusBarController = nil
    }
}
