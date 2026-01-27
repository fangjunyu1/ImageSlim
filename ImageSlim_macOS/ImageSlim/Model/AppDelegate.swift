//
//  AppDelegate.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/6/24.
//

import AppKit
import SwiftUI
import Combine

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    var cancellables = Set<AnyCancellable>()
    var appStorage = AppStorage.shared
    var iapManager = IAPManager.shared
    var sound = SoundManager.shared
    var imageArray = ImageArrayViewModel.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        // 初始化键盘监听事件
        KeyboardMonitor.shared.startMonitoring()
        
        // 获取内购信息的动态数据
        Task {
            await IAPManager.shared.loadProduct()
            await IAPManager.shared.handleTransactions()
        }
        
        // 计算统计中的使用记录
        StatisticsManager.StatisticsDate()
        
        // 根据设置中的菜单栏选项，创建菜单栏
        if AppStorage.shared.displayMenuBarIcon {
            statusBarController = StatusBarController()
        }
        
        // 监听 displayMenuBarIcon 的变化
        appStorage.$displayMenuBarIcon
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
        
        // MARK: 创建分栏视图
        
        // content 为左侧显示的轻压图片 TabView
        let menuVC = NSHostingController(rootView:
            MenuView()
                .environmentObject(appStorage)
                .environmentObject(iapManager)
                .environmentObject(sound)
                .environmentObject(imageArray)
        )
        // workspace 为右侧显示的主视图内容
        let workspaceVC = NSHostingController(rootView:
             ContentView()
                .environmentObject(appStorage)
                .environmentObject(iapManager)
                .environmentObject(sound)
                .environmentObject(imageArray)
        )
        
        // 创建 NSSplitViewController(分栏界面) 并添加子项
        let splitVC = NSSplitViewController()
        
        // 创建 NSSplitViewItem
        let sidebarItem = NSSplitViewItem(sidebarWithViewController: menuVC)
        sidebarItem.canCollapse = false // 不允许用户折叠
        let viewItem = NSSplitViewItem(viewController: workspaceVC)
        
        // 添加到控制器
        splitVC.addSplitViewItem(sidebarItem)
        splitVC.addSplitViewItem(viewItem)
        
        // MARK: 分栏视图创建完成
        
        // MARK: 创建 Window 窗口
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 550),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView], // 可以调大小
            backing: .buffered,
            defer: false)
        window.center()
        window.isReleasedWhenClosed = false
        window.contentViewController = splitVC
        window.minSize = NSSize(width: 600, height: 450)
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
    
    // 接收打开的图片文件
    func application(_ application: NSApplication, open urls: [URL]) {
        Task {
            await FileProcessingService.shared.fileImporter(urls)
        }
    }
}
